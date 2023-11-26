#TODO:SECURITY reenable this; was disabled because we couldnt figure out why csrf (in swagger/js) was interacting badly with SessionMiddleware, search for other instances of this comment
# https://stackoverflow.com/questions/16458166/how-to-disable-djangos-csrf-validation/47888695#47888695
class DisableCSRFMiddleware(object):

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        setattr(request, '_dont_enforce_csrf_checks', True)
        response = self.get_response(request)
        return response
