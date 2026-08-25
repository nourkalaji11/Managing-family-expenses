enum GlobalApiEndpoint {
  //TODO
  base("https://domain/api/v1"),

  //splash
  initialSettings("settings/init"),

  //auth
  register("register"),
  login("login"),
  social("social"),
  verifyOTP("verifyOTP"),
  sendOTP("sendOTP"),
  notifications("notifications"),
  markAsRead("notifications/{id}/markAsRead"),
  markAllAsRead("markAllAsRead");

  final String endpoint;

  const GlobalApiEndpoint(this.endpoint);

  // Example 1: final endpoint = GlobalApiEndpoint.login.endpoint;
  // Example 2: final endpoint = GlobalApiEndpoint.showPages[['articles', 1]];
  String operator [](List<Object> params) {
    final regExp = RegExp(r"\{(.*?)\}");
    final urlParamsCount =
        endpoint.replaceAll(regExp, '[^]').split('[^]').length - 1;
    assert(
      urlParamsCount == params.length,
      'Endpoint params count not correct',
    );
    int foundedParams = -1;
    return endpoint.replaceAllMapped(regExp, (_) {
      foundedParams++;
      return params[foundedParams].toString();
    });
  }
}
