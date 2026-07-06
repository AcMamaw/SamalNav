-- Add role column to profiles for RBAC
-- Run this in your Supabase SQL Editor

ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS role TEXT NOT NULL DEFAULT 'tourist'
CHECK (role IN ('tourist', 'establishment', 'administrator', 'super_admin'));

-- Example: assign roles to existing users (replace emails with yours)
-- UPDATE profiles SET role = 'establishment' WHERE email = 'owner@resort.com';
-- UPDATE profiles SET role = 'administrator' WHERE email = 'admin@samalnav.gov.ph';
-- UPDATE profiles SET role = 'super_admin' WHERE email = 'superadmin@samalnav.ph';

-- Optional: auto-create profile with tourist role on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, display_name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'role', 'tourist')
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    display_name = COALESCE(profiles.display_name, EXCLUDED.display_name);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
