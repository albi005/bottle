// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:sqflite/sqflite.dart' as _i779;

import '../db/database.dart' as _i783;
import '../db/log_repository.dart' as _i989;
import '../services/ble_scanner.dart' as _i226;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> initDependencies({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final databaseModule = _$DatabaseModule();
    await gh.singletonAsync<_i779.Database>(
      () => databaseModule.provideDatabase(),
      preResolve: true,
    );
    gh.singleton<_i989.LogRepository>(
      () => _i989.LogRepository(gh<_i779.Database>()),
    );
    gh.singleton<_i226.BleScanner>(
      () => _i226.BleScanner(gh<_i989.LogRepository>()),
    );
    return this;
  }
}

class _$DatabaseModule extends _i783.DatabaseModule {}
