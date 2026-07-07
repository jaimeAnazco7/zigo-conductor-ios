/// URLs oficiales Zigo: la app conductor siempre abre estas (no se sustituyen por el API).
const String kDefaultZigoTermsUrl = 'https://zigotaxi.com/terminos/';
const String kDefaultZigoPrivacyPolicyUrl = 'https://zigotaxi.com/politicas/';

bool isHttpOrHttpsUrl(String? s) {
  if (s == null) return false;
  final t = s.trim();
  return t.startsWith('http://') || t.startsWith('https://');
}
