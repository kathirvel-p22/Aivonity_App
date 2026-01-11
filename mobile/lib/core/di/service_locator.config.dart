// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:logger/logger.dart' as _i974;

import '../error/error_handler.dart' as _i1065;
import '../utils/logger.dart' as _i1007;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    gh.singleton<_i974.Logger>(() => Logger());
    gh.singleton<_i1007.AppLogger>(() => _i1007.AppLogger());
    gh.singleton<_i1065.ErrorHandler>(
        () => _i1065.ErrorHandler(gh<_i974.Logger>()));
    return this;
  }
}

