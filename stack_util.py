#!/usr/bin/env python

from oslo_log import log as logging
logger = logging.getLogger(__name__)

import sys
import traceback

class Flat_stack_util(object):

    def __init__(self):
        self.logger = logging.getLogger(
            __name__ +
            "." +
            self.__class__.__name__)

    def get_resource_name(self, stack, name):
        resources = self.gather_all_parent_resources(stack);
        for resource in resources:
            resource_id = resource.resource_id
            if (resource.name == name or (resource_id == name)):
                return resource.name

    def get_resource(self, stack, name):
        resources = self.gather_all_parent_resources(stack);
        for resource in resources:
            resource_id = resource.resource_id
            if (resource.name == name or (resource_id == name)):
                return resource


    def gather_all_parent_resources(self, stack):
        resources = [];
#         logger.warning("self.stack.root = %s" % type(stack.root_stack))
#         logger.warning(stacktraces())
        for key in stack.resources:
            resource = stack.resources[key]
            resources.append(resource);
        # Commenting out stack traversal 
#        if stack.root_stack is not None and stack.root_stack != stack:
#            logger.warning("calling traverse.stack")
#            parent_stack = stack.root_stack
#            return self.traverse_stacks(parent_stack, resources)
        #else:
        return resources

    def is_resource_in_current_stack(self, stack, name, interface_name):
        for key in stack.resources:
            resource = stack.resources[key]
            resource_id = resource.resource_id
            #logger.warning("resource id:  %s"  % resource_id)
            #logger.warning("resource name  %s"  % resource.name)
            #logger.warning("name passed in %s" % name)
            if (resource.has_interface(interface_name)
                and (resource.name == name or (resource_id == name))):
                #logger.warning("found in stack");
                return True;
        return False;

    def get_stack_name_for_resource(self, stack, name, interface_name):
         for key in stack.resources:
            resource = stack.resources[key]
            resource_id = resource.resource_id
            if (resource.has_interface(interface_name) and (resource.name == name or (resource_id == name))):
                return stack.name
         if stack.root_stack is not None and stack.root_stack != stack:
            parent_stack = stack.root_stack
            return self.traverse_stacks_name(parent_stack, name, interface_name)


    def traverse_stacks_name(self, stack, name, interface_name):
        if stack.root_stack is not None:
            parent_stack = stack.root_stack;
            logger.warning("traverse.stack = %s" % type(parent_stack))
            for key in parent_stack.resources:
                resource = parent_stack.resources[key]
                resource_id = resource.resource_id
                logger.warning("traverse.stack name var= %s" % name)
                logger.warning("traverse.stack resource name= %s" % resource.name)
                logger.warning("traverse.stack resource id= %s" % resource_id)
                logger.warning("traverse.stack interface name= %s" % interface_name)
                logger.warning("traverse.stack name= %s" % parent_stack.name)
                logger.warning("traverse.stack has interface= %s" % resource.has_interface(interface_name))
                value = resource_id == name;
                #logger.warning("traversing stack id = name = %s" % value)
                if ((resource.has_interface(interface_name)) and ((resource.name == name) or (resource_id == name))):
                    #logger.warning("IN return of travesral %s" % parent_stack.name)
                    return parent_stack.name
            if parent_stack.root_stack is not None and parent_stack != stack:
                self.traverse_stacks_name(parent_stack.root_stack, name, interface_name)
        return None

    def traverse_stacks(self, stack, resources):
        logger.warning("in traverse.stack")
        if stack.root_stack is not None:
            parent_stack = stack.root_stack;
            logger.warning("traverse.stack = %s" % type(parent_stack))
            for key in parent_stack.resources:
                parent_resource = parent_stack.resources[key]
                resources.append(parent_resource);
            if parent_stack.root_stack is not None and parent_stack != stack:
                self.traverse_stacks(parent_stack.root_stack, resources)
        return resources


def stacktraces():
    code = []
    for threadId, stack in sys._current_frames().items():
        code.append("\n# ThreadID: %s" % threadId)
        for filename, lineno, name, line in traceback.extract_stack(stack):
            code.append('File: "%s", line %d, in %s' % (filename, lineno, name))
            if line:
                code.append("  %s" % (line.strip()))

#     return highlight("\n".join(code), PythonLexer(), HtmlFormatter(
#       full=False,
#       # style="native",
#       noclasses=True))
    return "\n".join(code)
