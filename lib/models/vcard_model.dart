class VCardModel {
  String name;
  String company;
  String email;
  String phone;
  String website;
  String title;
  String address;

  VCardModel({
    required this.name,
    required this.company,
    this.email = '',
    this.phone = '',
    this.website = '',
    this.title = '',
    this.address = '',
  });

  // Convert the model to a vCard format string
  String toVCardString() {
    final List<String> vCardLines = ['BEGIN:VCARD', 'VERSION:3.0'];

    // Add name
    if (name.isNotEmpty) {
      final nameParts = name.split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';
      vCardLines.add('N:$lastName;$firstName;;;');
      vCardLines.add('FN:$name');
    }

    // Add organization
    if (company.isNotEmpty) {
      vCardLines.add('ORG:$company');
    }

    // Add title
    if (title.isNotEmpty) {
      vCardLines.add('TITLE:$title');
    }

    // Add email
    if (email.isNotEmpty) {
      vCardLines.add('EMAIL;TYPE=INTERNET:$email');
    }

    // Add phone
    if (phone.isNotEmpty) {
      vCardLines.add('TEL;TYPE=CELL:$phone');
    }

    // Add website
    if (website.isNotEmpty) {
      vCardLines.add('URL:$website');
    }

    // Add address
    if (address.isNotEmpty) {
      vCardLines.add('ADR;TYPE=HOME:;;$address;;;;');
    }

    vCardLines.add('END:VCARD');
    return vCardLines.join('\n');
  }

  // Create an empty VCardModel
  factory VCardModel.empty() {
    return VCardModel(
      name: '',
      company: '',
      email: '',
      phone: '',
      website: '',
      title: '',
      address: '',
    );
  }

  // Parse a vCard string into a VCardModel
  factory VCardModel.fromVCardString(String vCardString) {
    String parsedName = '';
    String parsedCompany = '';
    String parsedEmail = '';
    String parsedPhone = '';
    String parsedWebsite = '';
    String parsedTitle = '';
    String parsedAddress = '';

    final lines = vCardString.split('\n');
    for (final line in lines) {
      if (line.startsWith('FN:')) {
        parsedName = line.substring(3).trim();
      } else if (line.startsWith('ORG:')) {
        parsedCompany = line.substring(4).trim();
      } else if (line.startsWith('EMAIL')) {
        parsedEmail = line.split(':').last.trim();
      } else if (line.startsWith('TEL')) {
        parsedPhone = line.split(':').last.trim();
      } else if (line.startsWith('URL:')) {
        parsedWebsite = line.substring(4).trim();
      } else if (line.startsWith('TITLE:')) {
        parsedTitle = line.substring(6).trim();
      } else if (line.startsWith('ADR')) {
        final parts = line.split(':').last.split(';');
        if (parts.length > 2) {
          parsedAddress = parts[2].trim();
        }
      }
    }

    return VCardModel(
      name: parsedName,
      company: parsedCompany,
      email: parsedEmail,
      phone: parsedPhone,
      website: parsedWebsite,
      title: parsedTitle,
      address: parsedAddress,
    );
  }
}
