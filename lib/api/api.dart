
class API {
  final String host = "https://10.0.2.2:7261/";
  // final String hostData = "https://svkt1.huetechcoop.com/";

  Map<String, String> get headerSvkt1 => {
    "accept":
    "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
    "accept-language": "en-US,en;q=0.9,vi;q=0.8",
    "cache-control": "max-age=0",
    "content-type": "application/json",
    "priority": "u=1, i",
    "sec-ch-ua":
    "\"Chromium\";v=\"128\", \"Not;A=Brand\";v=\"24\", \"Microsoft Edge\";v=\"128\"",
    "sec-ch-ua-mobile": "?0",
    "sec-ch-ua-platform": "\"Windows\"",
    "sec-fetch-dest": "empty",
    "sec-fetch-mode": "cors",
    "sec-fetch-site": "cross-site",
    "upgrade-insecure-requests": "1",
    "referrer-policy": "strict-origin-when-cross-origin",
  };
}
