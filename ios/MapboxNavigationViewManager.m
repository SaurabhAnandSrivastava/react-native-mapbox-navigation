//
//  MapboxNavigationViewManager.m
//  react-native-mapbox-navigation
//
//  Created by Pawan Kushwaha on 10/07/2024.
//

#import "React/RCTViewManager.h"
#import "MapboxCoordinate.h"
#import "RCTConvert+MapboxNavigation.h"

@interface RCT_EXTERN_MODULE(MapboxNavigationViewManager, RCTViewManager)

RCT_EXPORT_VIEW_PROPERTY(onLocationChange, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onRouteProgressChange, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onError, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onCancelNavigation, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onArrive, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(startOrigin, NSArray)
RCT_CUSTOM_VIEW_PROPERTY(waypoints, NSArray, NSObject)
{
    MapboxCoordinateArray *coordinates = [RCTConvert MapboxCoordinateArray:json];
    [self performSelector:@selector(setWaypoints:coordinates:) withObject:view withObject:coordinates];
}

RCT_CUSTOM_VIEW_PROPERTY(stops, NSArray, NSObject)
{
    
    // Pass the NSArray (which is coming from React Native) directly to the Swift method
    [self performSelector:@selector(setStops:stopsArray:) withObject:view withObject:json];
}

RCT_CUSTOM_VIEW_PROPERTY(driverLocations, NSArray, NSObject)
{
    
    // Pass the NSArray (which is coming from React Native) directly to the Swift method
    [self performSelector:@selector(setDriverLocations:stopsArray:) withObject:view withObject:json];
}






RCT_EXPORT_VIEW_PROPERTY(destination, NSArray)
RCT_EXPORT_VIEW_PROPERTY(shouldSimulateRoute, BOOL)
RCT_EXPORT_VIEW_PROPERTY(showsEndOfRouteFeedback, BOOL)
RCT_EXPORT_VIEW_PROPERTY(showCancelButton, BOOL)
RCT_EXPORT_VIEW_PROPERTY(language, NSString)
RCT_EXPORT_VIEW_PROPERTY(mute, BOOL)

RCT_EXPORT_VIEW_PROPERTY(isPreview, BOOL)
RCT_EXPORT_VIEW_PROPERTY(waypointMarker, UIImage)





@end

