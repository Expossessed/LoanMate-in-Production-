-- =============================================================================
-- Migration: complete_student_registration
-- Purpose:   Atomically insert one row into all 7 student-related tables inside
--            a single plpgsql function. Because the entire function body runs
--            in one implicit transaction, any failure (constraint violation,
--            missing column, RLS block, etc.) causes a full rollback — no
--            partial / ghost accounts can form.
-- SECURITY:  SECURITY DEFINER — runs as the function owner, bypassing RLS for
--            its own inserts. EXECUTE is granted to `authenticated` only.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.complete_student_registration(
  p_user_id    uuid,
  p_student_id text,
  p_first_name text,
  p_last_name  text,
  p_course     text,
  p_year_level text
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_wallet_id uuid := gen_random_uuid();
  v_loan_id   uuid := gen_random_uuid();
BEGIN
  -- Guard: caller must own the target user row.
  IF auth.uid() <> p_user_id THEN
    RAISE EXCEPTION 'auth.uid() does not match p_user_id';
  END IF;

  -- 1. users
  INSERT INTO users (id, student_id, first_name, last_name, course, year_level,
                     enrollment_status, role, created_at)
  VALUES (p_user_id, p_student_id, p_first_name, p_last_name, p_course,
          p_year_level, 'active', 'student', now());

  -- 2. wallet
  INSERT INTO wallet (id, user_id, balance, savings_goal, current_savings)
  VALUES (v_wallet_id, p_user_id, 0, 0, 0);

  -- 3. loans  (placeholder row so FKs in child tables can be satisfied)
  INSERT INTO loans (id, user_id, amount, purpose, status, applied_at)
  VALUES (v_loan_id, p_user_id, 0, 'placeholder', 'pending', now());

  -- 4. repayment_schedule
  INSERT INTO repayment_schedule (id, loan_id, due_date, amount, status)
  VALUES (gen_random_uuid(), v_loan_id, now()::date, 0, 'pending');

  -- 5. documents
  INSERT INTO documents (id, user_id, loan_id, file_url, uploaded_at)
  VALUES (gen_random_uuid(), p_user_id, v_loan_id, NULL, now());

  -- 6. notifications  (welcome message)
  INSERT INTO notifications (id, user_id, type, message, is_read, created_at)
  VALUES (gen_random_uuid(), p_user_id, 'welcome', 'Welcome to LoanMate!', false, now());

  -- 7. transactions  ← `date` column is REQUIRED and was previously missing
  INSERT INTO transactions (id, wallet_id, type, amount, date, description)
  VALUES (gen_random_uuid(), v_wallet_id, 'init', 0, now(), 'Account created');
END;
$$;

-- Grant EXECUTE to authenticated users only; revoke from the PUBLIC pseudo-role.
GRANT EXECUTE ON FUNCTION public.complete_student_registration(uuid, text, text, text, text, text)
  TO authenticated;
REVOKE EXECUTE ON FUNCTION public.complete_student_registration(uuid, text, text, text, text, text)
  FROM PUBLIC;


