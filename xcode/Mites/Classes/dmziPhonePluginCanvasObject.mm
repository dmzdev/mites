#include "dmziPhonePluginCanvasObject.h"
#include <dmziPhoneModuleCanvas.h>
#include <dmziPhoneCanvasConsts.h>
#include <dmzObjectAttributeMasks.h>
#include <dmzObjectModule.h>
#include <dmzRuntimeConfig.h>
#include <dmzRuntimeConfigToTypesBase.h>
#include <dmzRuntimeDefinitions.h>
#include <dmzRuntimeObjectType.h>
#include <dmzRuntimePluginFactoryLinkSymbol.h>
#include <dmzRuntimePluginInfo.h>
#include <dmzTypesVector.h>
#include <dmzTypesMatrix.h>
#import <UIKit/UIKit.h>


dmz::iPhonePluginCanvasObject::iPhonePluginCanvasObject (
      const PluginInfo &Info, Config &local) :
      Plugin (Info),
      ObjectObserverUtil (Info, local),
      _log (Info),
      _defs (Info, &_log),
      _canvasModule (0),
      _canvasModuleName (),
      _defaultAttrHandle (0),
      _objectTable () {

   _init (local);
}


dmz::iPhonePluginCanvasObject::~iPhonePluginCanvasObject () {

   _objectTable.empty ();
}


// Plugin Interface
void
dmz::iPhonePluginCanvasObject::update_plugin_state (
      const PluginStateEnum State,
      const UInt32 Level) {

   if (State == PluginStateInit) {

   }
   else if (State == PluginStateStart) {

   }
   else if (State == PluginStateStop) {

   }
   else if (State == PluginStateShutdown) {

   }
}


void
dmz::iPhonePluginCanvasObject::discover_plugin (
      const PluginDiscoverEnum Mode,
      const Plugin *PluginPtr) {

   if (Mode == PluginDiscoverAdd) {

      if (!_canvasModule) {
         
         _canvasModule = iPhoneModuleCanvas::cast (PluginPtr, _canvasModuleName);
      }      
   }
   else if (Mode == PluginDiscoverRemove) {

      if (_canvasModule && (_canvasModule == iPhoneModuleCanvas::cast (PluginPtr))) {
         
         _objectTable.empty ();
         _canvasModule = 0;
      }
   }
}


// Object Observer Interface
void
dmz::iPhonePluginCanvasObject::create_object (
      const UUID &Identity,
      const Handle ObjectHandle,
      const ObjectType &Type,
      const ObjectLocalityEnum Locality) {
   
   Config data;
   ObjectType currentType (Type);
   
   if (_find_config_from_type (data, currentType)) {
      
      String name (currentType.get_name ());
      name << "." << ObjectHandle;
      
//      ObjectStruct *os (new ObjectStruct (ObjectHandle));
      
      UIImage *miteImage = [UIImage imageNamed:@"mite.png"];
      
      UIImageView *item = [[UIImageView alloc] initWithImage:miteImage];
      item.tag = ObjectHandle;
      
      ObjectModule *objMod (get_object_module ());
      
      if (objMod) {
         
         Vector pos;
         Matrix ori;
         
         objMod->lookup_position (ObjectHandle, _defaultAttrHandle, pos);
         objMod->lookup_orientation (ObjectHandle, _defaultAttrHandle, ori);
         
         item.center = CGPointMake (pos.get_x (), pos.get_z ());
      }
      
      _objectTable.store (ObjectHandle, item);
      
      if (_canvasModule) {
      
         _canvasModule->add_item (ObjectHandle, item);
      }
   }
}


void
dmz::iPhonePluginCanvasObject::destroy_object (
      const UUID &Identity,
      const Handle ObjectHandle) {

   UIImageView *item (_objectTable.remove (ObjectHandle));
   
   if (item) {

      if (_canvasModule) { _canvasModule->remove_item (ObjectHandle); }
      
      [item release];
      item = nil;
   }
}


void
dmz::iPhonePluginCanvasObject::update_object_position (
      const UUID &Identity,
      const Handle ObjectHandle,
      const Handle AttributeHandle,
      const Vector &Value,
      const Vector *PreviousValue) {

   if (AttributeHandle == _defaultAttrHandle) {
      
      UIImageView *item (_objectTable.lookup (ObjectHandle));
      
      if (item) {
            
         item.center = CGPointMake (Value.get_x (), Value.get_z ());
      }
   }
}


dmz::Boolean
dmz::iPhonePluginCanvasObject::_find_config_from_type (
      Config &local,
      ObjectType &objType) {
   
   const String Name (get_plugin_name ());
   
   Boolean found (objType.get_config ().lookup_all_config_merged (Name, local));
   
   if (!found) {
      
      ObjectType currentType (objType);
      currentType.become_parent ();
      
      while (currentType && !found) {
         
         if (currentType.get_config ().lookup_all_config_merged (Name, local)) {
            
            found = True;
            objType = currentType;
         }
         
         currentType.become_parent ();
      }
   }
   
   return found;
}


void
dmz::iPhonePluginCanvasObject::_init (Config &local) {

   Definitions defs (get_plugin_runtime_context ());

   _canvasModuleName = config_to_string ("module.canvas.name", local);
   
   _defaultAttrHandle = activate_default_object_attribute (
      ObjectCreateMask |
      ObjectDestroyMask |
      ObjectPositionMask /* |
      ObjectOrientationMask */);
}


extern "C" {

DMZ_PLUGIN_FACTORY_LINK_SYMBOL dmz::Plugin *
create_dmziPhonePluginCanvasObject (
      const dmz::PluginInfo &Info,
      dmz::Config &local,
      dmz::Config &global) {

   return new dmz::iPhonePluginCanvasObject (Info, local);
}

};
