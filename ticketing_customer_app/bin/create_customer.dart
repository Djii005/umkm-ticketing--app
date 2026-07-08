import 'dart:convert';
import 'dart:io';

void main() async {
  final envFile = File('.env');
  if (!await envFile.exists()) {
    print('Error: .env file not found.');
    exit(1);
  }

  final lines = await envFile.readAsLines();
  String? url;
  String? anonKey;
  for (var line in lines) {
    if (line.startsWith('SUPABASE_URL=')) {
      url = line.substring('SUPABASE_URL='.length).trim();
    } else if (line.startsWith('SUPABASE_ANON_KEY=')) {
      anonKey = line.substring('SUPABASE_ANON_KEY='.length).trim();
    }
  }

  if (url == null || anonKey == null) {
    print('Error: SUPABASE_URL or SUPABASE_ANON_KEY missing in .env.');
    exit(1);
  }

  final email = 'customer_test2@gmail.com';
  final password = 'customerpassword123';
  final fullName = 'Customer Test';

  print('Registering customer account: $email...');

  final client = HttpClient();
  try {
    final signupUri = Uri.parse('$url/auth/v1/signup');
    final request = await client.postUrl(signupUri);
    
    request.headers.contentType = ContentType.json;
    request.headers.add('apikey', anonKey);

    final requestBody = jsonEncode({
      'email': email,
      'password': password,
      'data': {
        'full_name': fullName,
        'role': 'customer',
      }
    });

    request.write(requestBody);
    final response = await request.close();

    final responseBody = await response.transform(utf8.decoder).join();
    if (response.statusCode == 200 || response.statusCode == 201) {
      print('-----------------------------------------');
      print('SUCCESS: Customer account created successfully!');
      print('Email: $email');
      print('Password: $password');
      print('-----------------------------------------');
    } else {
      print('Error (Status ${response.statusCode}): $responseBody');
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }

  exit(0);
}
