class AdminAccess {
  static const Set<String> bootstrapEmails = {'hsab7164@gmail.com'};

  static bool isBootstrapAdminEmail(String? email) {
    if (email == null) {
      return false;
    }

    return bootstrapEmails.contains(email.trim().toLowerCase());
  }
}
