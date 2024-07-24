import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

final logger = Logger();

class ApiService {
  final String baseUrl = Config.baseUrl;

  Future<List<dynamic>> getRoles() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/roles'));
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('No se pudieron cargar roles');
      }
    } catch (e) {
      logger.e('Error al obtener roles: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getEstados() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/estados'));
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('No se pudieron cargar estados');
      }
    } catch (e) {
      logger.e('Error al obtener estados: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getMunicipios(int estadoId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/municipios/estado/$estadoId'));
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('No se pudieron cargar municipios');
      }
    } catch (e) {
      logger.e('Error al obtener municipios: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getInfoDivulgacion() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/infodivulgacion'));
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('No se pudieron cargar info divulgacion');
      }
    } catch (e) {
      logger.e('Error al obtener info divulgacion: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> registerUser(Map<String, dynamic> userData) async {
  final response = await http.post(
    Uri.parse('${Config.baseUrl}/auth/register'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(userData),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else if (response.statusCode == 400) {
    throw Exception('¡Este correo electrónico ya se encuentra registrado en la aplicación!');
  } else {
    throw Exception('Falló al registrar el usuario');
  }
}

  Future<String> verifyEmail(int usuarioId, String codigo) async {
    final response = await http.post(
      Uri.parse('${Config.baseUrl}/usuarios/verificar-correo?usuarioId=$usuarioId&codigo=$codigo'),
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Fallo al verificar el Email');
    }
  }

  Future<void> resendVerificationCode(int usuarioId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/usuarios/reenviar-codigo?usuarioId=$usuarioId'),
    );

    if (response.statusCode == 500) {
      throw Exception('Fallo al reenviar el código de verificación');
    }if (response.statusCode == 400) {
      throw Exception('No se puede enviar un nuevo código, el anterior aún no caduca');
    }
  }
  
  Future<String> loginUser(String correo, String contrasena) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'correo': correo,
        'contrasena': contrasena,
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      return responseBody['token'];
    } else if (response.statusCode == 500) {
      throw Exception('Correo o contraseña incorrectos');
    } else {
      throw Exception('Error al iniciar sesión');
    }
  }

  String _decodeBase64(String str) {
    String output = str.replaceAll('-', '+').replaceAll('_', '/');
    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      default:
        throw Exception('Base64 inválido');
    }
    return utf8.decode(base64Url.decode(output));
  }

  Map<String, dynamic> parseJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Token inválido');
    }
    final payload = _decodeBase64(parts[1]);
    return json.decode(payload);
  }

  Future<Map<String, dynamic>> getUserData(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    if (token == null) {
      throw Exception('Token no encontrado');
    }
  
    final response = await http.get(
      Uri.parse('$baseUrl/usuarios/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener los datos del usuario');
    }
  }

  Future<void> updateUserData(int userId, Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final response = await http.put(
      Uri.parse('$baseUrl/usuarios/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(userData),
    );

    if (response.statusCode != 200) {
      throw Exception('Fallo al actualizar datos del usuario');
    }
  }

  Future<void> logout(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/logout'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to log out');
    }
  }

  Future<void> sendResetCode(String correo) async {
    final response = await http.post(
      Uri.parse('$baseUrl/usuarios/enviar-codigo-cambio-contrasena?correo=$correo'),
      headers: {
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 500) {
      throw Exception('No se púdo enviar el código');
    }if (response.statusCode == 400) {
      throw Exception('Este correo no se encuentra registrado en la aplicación');
    }
  }

  Future<void> resetPassword(String correo, String codigo, String nuevaContrasena) async {
    final response = await http.post(
      Uri.parse('$baseUrl/usuarios/cambiar-contrasena?correo=$correo&codigo=$codigo&nuevaContrasena=$nuevaContrasena'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );  
    if (response.statusCode == 500) {
      throw Exception('Fallo al reestablecer la contraseña');
    }if (response.statusCode == 400) {
      throw Exception('Código incorrecto o caducado');
    }
  }

  Future<Map<String, dynamic>> createJob(Map<String, dynamic> jobData) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    if (token == null) {
      throw Exception('Token no encontrado');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/empleos'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(jobData),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al crear empleo');
    }
  }

  Future<List<dynamic>> getMunicipiosPorEstados(List<int> estadosIds) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/municipios/estados'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(estadosIds),
      );
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('No se pudieron cargar municipios');
      }
    } catch (e) {
      logger.e('Error al obtener municipios: $e');
      rethrow;
    }
  }
  
}