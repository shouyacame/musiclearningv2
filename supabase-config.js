const SUPABASE_URL = 'https://ezzftybslkmyxswexpbe.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV6emZ0eWJzbGtteXhzd2V4cGJlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA5MDQwODUsImV4cCI6MjA5NjQ4MDA4NX0.ZKXi0PqrRcATMlOEz3P4Zp314MyaYaxJmAR5JRel5MM';

const db = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: { persistSession: true, storageKey: 'shamisen-auth' }
});
