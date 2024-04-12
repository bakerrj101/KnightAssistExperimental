import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:knightassist/src/features/events/providers/events_provider.dart';
import 'package:knightassist/src/global/providers/all_providers.dart';
import 'package:knightassist/src/global/states/future_state.codegen.dart';
import 'package:knightassist/src/global/widgets/custom_dialog.dart';
import 'package:knightassist/src/global/widgets/custom_text.dart';
import 'package:knightassist/src/helpers/extensions/extensions.dart';

import '../../../config/routing/routing.dart';
import '../../../global/widgets/async_value_widget.dart';
import '../../../global/widgets/custom_circular_loader.dart';
import '../../../global/widgets/custom_text_button.dart';
import '../../../global/widgets/error_response_handler.dart';
import '../../../global/widgets/scrollable_column.dart';
import '../../../helpers/constants/constants.dart';
import '../../auth/enums/user_role_enum.dart';
import '../../volunteers/models/volunteer_model.dart';
import '../../volunteers/providers/volunteers_provider.dart';

class EventDetailsScreen extends HookConsumerWidget {
  const EventDetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(currentEventProvider);
    final authProv = ref.watch(authProvider.notifier);
    final eventsProv = ref.watch(eventsProvider);

    ref.listen<FutureState<String>>(
      rsvpStateProvider,
      (previous, rsvpState) async {
        rsvpState.maybeWhen(
          data: (message) async {
            await showDialog<bool>(
                context: context,
                builder: (ctx) => CustomDialog.alert(
                      title: 'Success',
                      body: message,
                      buttonText: 'OK',
                      onButtonPressed: () => AppRouter.pop(),
                    ));
          },
          failed: (reason) async {
            await showDialog<bool>(
              context: context,
              builder: (ctx) => CustomDialog.alert(
                title: 'Failed',
                body: reason,
                buttonText: 'Retry',
              ),
            );
          },
          orElse: () {},
        );
      },
    );

    return Scaffold(
      body: SafeArea(
        child: ScrollableColumn(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.only(
                  left: 20, right: 20, top: 10, bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Icon
                  InkResponse(
                    radius: 26,
                    child: const Icon(
                      Icons.arrow_back_sharp,
                      size: 32,
                      color: Colors.white,
                    ),
                    onTap: () => AppRouter.pop(),
                  ),
                  // Title
                  /*Text(
                    event!.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),*/
                  const SizedBox(width: 32),
                ],
              ),
            ),

            CachedNetworkImage(
              imageUrl: event!.profilePicPath,
            ),

            // Event Details
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                    event!.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                    CustomText(
                      event.description,
                      maxLines: 10,
                      textAlign: TextAlign.start,
                      fontSize: 18,
                    ),

                    Insets.gapH(10),

                    // Location
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 23,
                        ),
                        Insets.gapW(7),
                        CustomText(
                          event.location,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          fontSize: 18,
                        ),
                      ],
                    ),

                    Insets.gapH(5),

                    // Date
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          size: 23,
                        ),
                        Insets.gapW(7),
                        CustomText(
                          event.startTime.toDateString('d MMM, y'),
                          textAlign: TextAlign.center,
                          fontSize: 18,
                        )
                      ],
                    ),

                    Insets.gapH(5),

                    // Times
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 23,
                        ),
                        Insets.gapW(7),
                        CustomText(
                          '${TimeOfDay.fromDateTime(event.startTime).format(context)} - ${TimeOfDay.fromDateTime(event.endTime).format(context)}',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          fontSize: 18,
                        ),
                      ],
                    ),

                    Insets.gapH(5),

                    Row(
                      children: [
                        const Icon(
                          Icons.person,
                          size: 23,
                        ),
                        Insets.gapW(7),
                        CustomText(
                          '${event.registeredVolunteerIds.length} / ${event.maxAttendees} Spots Reserved',
                          textAlign: TextAlign.center,
                          fontSize: 18,
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Edit Button if sponsoring org
            Visibility(
              visible: authProv.currentUserRole == UserRole.ORGANIZATION &&
                  authProv.currentUserId == event.sponsoringOrganizationId,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: CustomTextButton(
                  color: AppColors.primaryColor,
                  child: const Center(
                    child: Text(
                      'Edit Event',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        letterSpacing: 0.7,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  onPressed: () {
                    AppRouter.pushNamed(Routes.EditEventScreenRoute);
                  },
                ),
              ),
            ),

            // RSVP button if student and not in event history
            // Leave Feedback button if student and in event history
            Visibility(
              visible: authProv.currentUserRole == UserRole.VOLUNTEER,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Consumer(
                  builder: (context, ref, child) {
                    return AsyncValueWidget<VolunteerModel>(
                      value: ref.watch(userVolunteerProvider),
                      loading: () => const CustomCircularLoader(),
                      error: (error, st) => ErrorResponseHandler(
                        error: error,
                        stackTrace: st,
                        retryCallback: () => ref.refresh(userVolunteerProvider),
                      ),
                      data: (volunteer) {
                        if (volunteer.eventHistoryIds.contains(event.id)) {
                          return CustomTextButton(
                            width: double.infinity,
                            color: AppColors.secondaryColor,
                            onPressed: () => AppRouter.pushNamed(
                                Routes.LeaveFeedbackScreenRoute),
                            child: const Center(
                              child: Text(
                                'Leave Feedback',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  letterSpacing: 0.7,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        } else {
                          return CustomTextButton(
                            width: double.infinity,
                            color: volunteer.eventRsvpIds.contains(event.id) ||
                                    event.maxAttendees <=
                                        event.registeredVolunteerIds.length
                                ? AppColors.buttonGreyColor
                                : AppColors.secondaryColor,
                            child: Consumer(
                              builder: (context, ref, child) {
                                final _rsvpState = ref.watch(rsvpStateProvider);
                                return _rsvpState.maybeWhen(
                                  loading: () => const Center(
                                    child: SpinKitRing(
                                      color: Colors.white,
                                      size: 30,
                                      lineWidth: 4,
                                      duration: Duration(milliseconds: 1100),
                                    ),
                                  ),
                                  orElse: () => child!,
                                );
                              },
                              child: Center(
                                child: Text(
                                  volunteer.eventRsvpIds.contains(event.id)
                                      ? 'Cancel RSVP'
                                      : event.maxAttendees <=
                                              event
                                                  .registeredVolunteerIds.length
                                          ? 'Event Full'
                                          : 'RSVP',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    letterSpacing: 0.7,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            onPressed: () async {
                              if (event.maxAttendees <=
                                  event.registeredVolunteerIds.length) {
                                return;
                              }
                              if (volunteer.eventRsvpIds.contains(event.id)) {
                                await eventsProv.cancelRSVP(
                                  eventId: event.id,
                                  eventName: event.name,
                                );
                              } else {
                                await eventsProv.addRSVP(
                                  eventId: event.id,
                                  eventName: event.name,
                                );
                              }
                            },
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
