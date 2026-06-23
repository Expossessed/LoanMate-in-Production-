-- ══════════════════════════════════════════════════════════════════
-- ACTIVE LOANS TABLE — Run in Supabase Dashboard > SQL Editor
-- ══════════════════════════════════════════════════════════════════
-- This table tracks the live remaining balance per approved loan.
-- It is updated whenever a loan payment transaction is made.
-- ══════════════════════════════════════════════════════════════════

-- 1) Create the table
CREATE TABLE IF NOT EXISTS active_loans (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  loan_id           UUID NOT NULL REFERENCES loans(id) ON DELETE CASCADE,
  user_id           UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  original_amount   NUMERIC(12, 2) NOT NULL DEFAULT 0,
  remaining_balance NUMERIC(12, 2) NOT NULL DEFAULT 0,
  monthly_payment   NUMERIC(12, 2) NOT NULL DEFAULT 0,
  start_date        DATE NOT NULL DEFAULT CURRENT_DATE,
  last_payment_date TIMESTAMPTZ,
  created_at        TIMESTAMPTZ DEFAULT now(),
  updated_at        TIMESTAMPTZ DEFAULT now()
);

-- 2) Enable Row Level Security
ALTER TABLE active_loans ENABLE ROW LEVEL SECURITY;

-- 3) RLS Policies
CREATE POLICY "Users can read own active loans"
  ON active_loans FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own active loans"
  ON active_loans FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own active loans"
  ON active_loans FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 4) Trigger: auto-update updated_at on every row change
CREATE OR REPLACE FUNCTION update_active_loans_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_active_loans_updated_at
  BEFORE UPDATE ON active_loans
  FOR EACH ROW EXECUTE FUNCTION update_active_loans_timestamp();

-- 5) Populate active_loans from existing approved/active loans
--    Run this once after creating the table to seed existing data.
INSERT INTO active_loans (loan_id, user_id, original_amount, remaining_balance, monthly_payment, start_date)
SELECT
  l.id           AS loan_id,
  l.user_id      AS user_id,
  l.amount       AS original_amount,
  l.amount       AS remaining_balance,   -- starts at full amount; reduce as payments come in
  COALESCE(
    (SELECT rs.amount FROM repayment_schedule rs
      WHERE rs.loan_id = l.id
      ORDER BY rs.due_date ASC LIMIT 1),
    0
  )              AS monthly_payment,
  COALESCE(l.approved_at::DATE, l.applied_at::DATE, CURRENT_DATE) AS start_date
FROM loans l
WHERE l.status IN ('approved', 'active', 'partial')
ON CONFLICT DO NOTHING;

-- ══════════════════════════════════════════════════════════════════
-- ALSO: Update active_loans remaining_balance when a payment is made
-- Create this trigger on the transactions table so that every
-- 'payment' type transaction automatically reduces the balance.
-- ══════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION reduce_active_loan_on_payment()
RETURNS TRIGGER AS $$
DECLARE
  v_user_id UUID;
BEGIN
  -- Only act on payment-type transactions
  IF NEW.type <> 'payment' THEN
    RETURN NEW;
  END IF;

  -- Find the user who owns this wallet
  SELECT user_id INTO v_user_id
  FROM wallet
  WHERE id = NEW.wallet_id;

  -- Reduce the remaining_balance of the user's active loans (FIFO)
  UPDATE active_loans
  SET
    remaining_balance   = GREATEST(0, remaining_balance - NEW.amount),
    last_payment_date   = now(),
    updated_at          = now()
  WHERE user_id = v_user_id
    AND remaining_balance > 0
  -- Only update the oldest active loan first
  AND id = (
    SELECT id FROM active_loans
    WHERE user_id = v_user_id AND remaining_balance > 0
    ORDER BY start_date ASC
    LIMIT 1
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_reduce_loan_on_payment
  AFTER INSERT ON transactions
  FOR EACH ROW EXECUTE FUNCTION reduce_active_loan_on_payment();
