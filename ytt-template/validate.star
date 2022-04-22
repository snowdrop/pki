# doc: https://carvel.dev/ytt/docs/v0.40.0/lang-ref-ytt-library/
load("@ytt:data", "data")
load("@ytt:assert", "assert")

def validate_namespace():
  data.values.namespace or assert.fail("Kubernetes namespace should be provided")
end

def generate_harbor_tls():
  for key in ["tls.crt", "tls.key"]:
    if getattr(data.values.Certificate, key):
      return False
    end
  end
  return True
end

def validate_all():
  validate_funcs = [
    validate_namespace,
  ]
  for validate_func in validate_funcs:
     validate_func()
  end
end

# validate all data values
validate_all()

# As we load all the data values here, then they should be re-exported to access them from overlays, lib, etc
values = data.values