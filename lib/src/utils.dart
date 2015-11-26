library pubglobalupdate.src.utils;

///
/// remove last and first char
/// (if length is at least 2)
///
insetString(String source, [int offset = 1]) {
  if (source.length > 1) {
    return source.substring(offset, source.length - offset);
  } else {
    return source;
  }
}

///
/// remove enclosing " or '
///
extractSource(String source) {
  if (source.startsWith('"') && source.endsWith('"')) {
    return extractSource(insetString(source));
  }
  if (source.startsWith("'") && source.endsWith("'")) {
    return extractSource(insetString(source));
  }
  return source;
}
