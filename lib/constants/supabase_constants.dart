class SupabaseConstants {
  static const String url = 'https://sssxfpfgctakutwbbszx.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNzc3hmcGZnY3Rha3V0d2Jic3p4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDEyOTUxNzAsImV4cCI6MjA1Njg3MTE3MH0.TIQO7BDJqdOUPV0olfQvbHjJ5HTsWFA1BXwclVFyCXU';

  /// Auth table
  /// Users Table
  static const String usersTable = 'Users';
  static const String usersCreatedAt = 'created_at';
  static const String usersFullName = 'fullName';
  static const String usersEmail = 'email';
  static const String usersPassword = 'password';
  static const String usersPhoneNumber = 'phoneNumber';
  static const String usersImageUrl = 'image_url';
  static const String usersUserId = 'UID';
  /// Messages Table
  static const String messagesTable = 'Messages';
  static const String messagesSender = 'sender';
  static const String messagesReceiver = 'receiver';
  static const String messagesText = 'text';
  static const String messagesCreatedAt = 'created_at';

  /// Storages
  static const String storageProfilePictures = 'profile-pictures';

}