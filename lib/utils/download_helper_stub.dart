// Заглушка для non-web платформ — ничего не делает.
// На Android экспорт будет реализован через share_plus или path_provider.
void saveFileAs(List<int> bytes, String filename, {String mimeType = 'application/octet-stream'}) {
  // TODO: реализовать через share_plus на Android
}
