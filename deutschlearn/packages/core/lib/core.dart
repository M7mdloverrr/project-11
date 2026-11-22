/// DeutschLearn shared models, environment config, backend interfaces with
/// Supabase implementations, and the Riverpod providers that wire them.
library;

export 'src/backend/admin_repository.dart';
export 'src/backend/auth_gateway.dart';
export 'src/backend/backend_bootstrap.dart';
export 'src/backend/link_repository.dart';
export 'src/backend/profile_repository.dart';
export 'src/backend/supabase_admin_repository.dart';
export 'src/backend/supabase_auth_gateway.dart';
export 'src/backend/supabase_link_repository.dart';
export 'src/backend/supabase_profile_repository.dart';
export 'src/backend/unconfigured_backend.dart';
export 'src/env.dart';
export 'src/failure.dart';
export 'src/models/admin.dart';
export 'src/models/cefr_level.dart';
export 'src/models/link.dart';
export 'src/models/profile.dart';
export 'src/models/role.dart';
export 'src/models/teacher_code.dart';
export 'src/providers.dart';
