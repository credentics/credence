enum ImportSource {
  onePassword,
  bitwarden,
  chrome,
  safari,
  lastPass,
}

extension ImportSourceX on ImportSource {
  String get label => switch (this) {
    ImportSource.onePassword => '1Password',
    ImportSource.bitwarden => 'Bitwarden',
    ImportSource.chrome => 'Chrome',
    ImportSource.safari => 'Safari',
    ImportSource.lastPass => 'LastPass',
  };

  String get fileType => switch (this) {
    ImportSource.onePassword => '1PUX / CSV',
    ImportSource.bitwarden => 'JSON',
    ImportSource.chrome => 'CSV',
    ImportSource.safari => 'CSV',
    ImportSource.lastPass => 'CSV',
  };
}
