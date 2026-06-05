class AppConfig {
  const AppConfig._();

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://yhpbiqtadbycedossnhh.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
        'eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlocGJpcXRhZGJ5Y2Vkb3NzbmhoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc2OTAzMTUsImV4cCI6MjA5MzI2NjMxNX0.'
        '3v8Sus5O-XvpnGh__IxZp06weW7OsCv6XnfudF_oaak',
  );
  static const coinGeckoProApiKey = String.fromEnvironment(
    'COINGECKO_PRO_API_KEY',
  );
  static const moralisApiKey = String.fromEnvironment('MORALIS_API_KEY');
  static const alchemyApiKey = String.fromEnvironment('ALCHEMY_API_KEY');
  static const geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
}
