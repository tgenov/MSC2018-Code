import json
import os
from deepmerge import Merger

class GraphGenerator(object):
      """Convert a list of key-value luples into a graph-like hash.
       e.g [ ('key1', 'value1'), ('key2', value2') ]
       State is persisted to disk in JSON format
       """

      def __init__(self, filename='graph.json'):
            self.filename = filename
            self.dict_merger = Merger([(list, ["append"]), (dict, ["merge"])], ["override"], ["override"])
            self.load()

      def __del__(self):
            self.persist()

      def load(self):
            '''Load graph from file'''
            try:
              with open(self.filename) as f:
                self.graph = json.load(f)
            except IOError:
                self.graph = {}

      def persist(self):
            ''' Persist graph to file'''
            with open('{}.new'.format(self.filename), 'w') as json_output:
              json.dump(self.graph, json_output)
              os.rename('{}.new'.format(self.filename), self.filename)

      def add_list(self, list):
            """ list = [ ('key1', 'value1'), ('key2', 'value2')...('keyN', 'valueN') ] """
            new_graph = self._parse_list(list)
            self.dict_merger.merge(self.graph, new_graph)

      def _parse_list(self, list):
            try:
              key, value = list.pop(0)
              return self._generate_node(key, value, self._parse_list(list))
            except IndexError:
              return {}

      def _generate_node(self, key, value, edges):
            return {key: {'value': value, '_edges': edges}}

generator = GraphGenerator()
