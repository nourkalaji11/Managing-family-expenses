enum GlobalApiEndpoint {
  // TODO(deploy): point this at the real host once the API is deployed.
  //
  // The path is `/api` with NO version prefix. `routes/api.php` registers
  // `/register`, `/login`, `/dashboard`, `/transactions`, ... directly under
  // it, so the previous `/api/v1` value pointed at routes that do not exist.
  //
  // To run against a local Laravel server:
  //   Android emulator → http://10.0.2.2:8000/api   (10.0.2.2 is the host's
  //                       loopback as seen from inside the emulator)
  //   iOS simulator    → http://127.0.0.1:8000/api
  //   Physical device  → http://<your-LAN-ip>:8000/api
  // Plain HTTP also needs the cleartext opt-in already set in
  // `android/app/src/debug/AndroidManifest.xml` (debug builds only).
  base("https://domain/api"),

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
