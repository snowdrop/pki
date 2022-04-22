# doc: https://carvel.dev/ytt/docs/v0.40.0/lang-ref-ytt/
load("@ytt:data", "data")

def generate_endpoint_tls():
  for key in ["tls.crt", "tls.key"]:
    if getattr(data.values.Certificate, key):
      return False
    end
  end
  return True
end