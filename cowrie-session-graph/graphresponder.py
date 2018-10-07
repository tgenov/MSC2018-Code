import json

from graphresponder import UnknownCommand


class GraphResponder(object):
    """A stateful responder which stores its command-response pairs in a graph.
     Calling the response() method does depth-traversal."""

    GRAPH_BLACKLIST_KEYS = ['_edges']

    def __init__(self, filename='graph.json'):
        self.filename = filename
        self.load()
        self.stack = None

    def reset_state(self):
        """Reset the pointer to the root of the graph"""
        self.stack = None

    def load(self):
        """Load graph from JSON file"""
        try:
            with open(self.filename) as graph_file:
                self.graph = json.load(graph_file)
        except IOError:
            self.graph = {}

    def response(self, command):
        """Return the response for a particular command"""
        try:
            if self.stack:
                response = self.stack[command]['value']
                self.stack = self.stack[command]['_edges']
            else:
                response = self.graph[command]['value']
                self.stack = self.graph[command]['_edges']
            return response
        except KeyError:
            raise UnknownCommand

    def known_commands(self):
        """Return the list of known commands at the current tree depth"""
        if self.stack:
            commands = self._get_keys(self.stack)
        else:
            commands = self._get_keys(self.graph)
        return commands

    def _get_keys(self, dictionary):
        """Exclude meta-keys from the graph dictionary"""
        return [key for key in dict.keys(dictionary) if key not in self.GRAPH_BLACKLIST_KEYS]


RESPONDER = GraphResponder()
