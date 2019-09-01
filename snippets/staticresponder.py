import json
from cowrie.core.config import CONFIG
from twisted.python import log

class StaticResponder(object):

    def __init__(self):
        self.__load_responses()

    def command_exists(self, command):
        return command in dict.keys(self.lookup_table)


    def response(self, command):
        return self.lookup_table[command]

    def __load_responses(self):
        db_file = CONFIG.get('honeypot', 'static_responder')
        try:
            with open(db_file) as f:
                self.lookup_table = json.load(f)
        except IOError:
            self.lookup_table = {}

        log.msg('Loaded Static Responder from {}'.format(db_file))

staticresponder = StaticResponder()