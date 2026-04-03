// Cloudinary Configuration
class CloudinaryConfig {
  static const String cloudName = 'dnrr0cmo3'; // Your Cloudinary cloud name
  static const String uploadUrl = 'https://api.cloudinary.com/v1_1/dnrr0cmo3/image/upload';
  
  // For unsigned uploads - use this in production
  static const String uploadPreset = 'ml_default'; // Default preset (works without authentication)
}
