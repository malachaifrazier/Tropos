@import CoreLocation;
@import TroposCore;
#import "RACSignal+TROperators.h"
#import "Secrets.h"
#import "TRWeatherController.h"
#import "TRWeatherUpdate+Analytics.h"
#import "TRSettingsController+TRObservation.h"
#import "TRAnalyticsController.h"

@interface TRWeatherController ()

@property (nonatomic) TRWeatherUpdater *weatherUpdater;

@property (nonatomic) TRSettingsController *settingsController;
@property (nonatomic) RACSignal *unitSystemChanged;

@property (nonatomic) TRWeatherViewModel *viewModel;
@property (nonatomic) NSError *weatherUpdateError;

@end

@implementation TRWeatherController

#pragma mark - Initializers

- (instancetype)init
{
    self = [super init];
    if (!self) return nil;

    self.weatherUpdater = [[TRWeatherUpdater alloc] initWithForecastAPIKey:TRForecastAPIKey];
    self.settingsController = [TRSettingsController new];
    self.unitSystemChanged = [[self.settingsController unitSystemChanged] replayLastLazily];

    RAC(self, viewModel) = [[self latestWeatherUpdates] map:^id(TRWeatherUpdate *update) {
        return [[TRWeatherViewModel alloc] initWithWeatherUpdate:update];
    }];

    RAC(self, weatherUpdateError) = [self.updateWeatherCommand.errors doNext:^(NSError *error) {
        [[TRAnalyticsController sharedController] trackError:error eventName:@"Error: Weather Update"];
    }];

    self.weatherUpdater.onWeatherUpdated = ^(TRWeatherUpdate *update) {
        [[TRAnalyticsController sharedController] trackEvent:update];
        [[TRWatchUpdateController defaultController] sendWeatherUpdate:update];
        [[TRWeatherUpdateCache new] archiveWeatherUpdate:update];
    };

    return self;
}

- (RACCommand *)updateWeatherCommand
{
    return self.weatherUpdater.command;
}

- (RACSignal *)latestWeatherUpdates
{
    TRWeatherUpdate *cachedUpdate = [[TRWeatherUpdateCache new] latestWeatherUpdate];
    RACSignal *weatherUpdates = [self.updateWeatherCommand.executionSignals startWith:[RACSignal return:cachedUpdate]];

    return [[weatherUpdates switchToLatest] filter:^BOOL(TRWeatherUpdate *update) {
        return update != nil;
    }];
}

#pragma mark - Properties

- (RACSignal *)status
{
    RACSignal *initialValue = [RACSignal return:nil];
    RACSignal *success = [RACObserve(self, viewModel.updatedDateString) ignore:nil];
    RACSignal *error = [[RACObserve(self, weatherUpdateError) ignore:nil] mapReplace:nil];

    return [RACSignal merge:@[initialValue, success, error]];
}

- (RACSignal *)locationName
{
    RACSignal *location = [[self.updateWeatherCommand.executionSignals
        map:^(RACSignal *update) {
            RACSignal *updatedLocation = [update then:^{
                return RACObserve(self, viewModel.locationName);
            }];
            return [updatedLocation startWith:NSLocalizedString(@"CheckingWeather", nil)];
        }]
        switchToLatest];

    RACSignal *error = [[RACObserve(self, weatherUpdateError)
        ignore:nil]
        mapReplace:NSLocalizedString(@"UpdateFailed", nil)];

    return [[RACSignal merge:@[location, error]] startWith:nil];
}

- (RACSignal *)conditionsImage
{
    return RACObserve(self, viewModel.conditionsImage);
}

- (RACSignal *)conditionsDescription
{
    return RACObserve(self, viewModel.conditionsDescription);
}

- (RACSignal *)windDescription
{
    return [[RACObserve(self, viewModel.windDescription) combineLatestWith:self.unitSystemChanged] map:^id(id value) {
        return self.viewModel.windDescription;
    }];
}

- (RACSignal *)highLowTemperatureDescription
{
    return [[RACObserve(self, viewModel.temperatureDescription) combineLatestWith:self.unitSystemChanged] map:^id(RACTuple *tuple) {
        return self.viewModel.temperatureDescription;
    }];
}

- (RACSignal *)dailyForecastViewModels
{
    return RACObserve(self, viewModel.dailyForecasts);
}

- (RACSignal *)precipitationDescription
{
    return RACObserve(self, viewModel.precipitationDescription);
}

@end
