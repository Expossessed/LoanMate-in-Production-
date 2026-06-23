-- Run this in your Supabase Dashboard > SQL Editor
-- This adds write policies so the app can actually update/insert data

-- ═══ WALLET TABLE ═══
-- Allow users to update their own wallet
CREATE POLICY "Users can update own wallet"
  ON wallet FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Allow users to read their own wallet
CREATE POLICY "Users can read own wallet"
  ON wallet FOR SELECT
  USING (auth.uid() = user_id);

-- ═══ TRANSACTIONS TABLE ═══
-- Allow users to insert transactions for their own wallet
CREATE POLICY "Users can insert own transactions"
  ON transactions FOR INSERT
  WITH CHECK (
    wallet_id IN (
      SELECT id FROM wallet WHERE user_id = auth.uid()
    )
  );

-- Allow users to read their own transactions
CREATE POLICY "Users can read own transactions"
  ON transactions FOR SELECT
  USING (
    wallet_id IN (
      SELECT id FROM wallet WHERE user_id = auth.uid()
    )
  );
