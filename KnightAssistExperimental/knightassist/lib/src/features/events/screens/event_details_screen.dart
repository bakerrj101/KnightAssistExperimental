import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:knightassist/src/config/routing/app_router.dart';
import 'package:knightassist/src/features/auth/enums/user_role_enum.dart';
import 'package:knightassist/src/features/events/providers/events_provider.dart';
import 'package:knightassist/src/features/volunteers/models/volunteer_model.codegen.dart';
import 'package:knightassist/src/features/volunteers/providers/volunteers_provider.dart';
import 'package:knightassist/src/global/providers/all_providers.dart';
import 'package:knightassist/src/global/widgets/async_value_widget.dart';
import 'package:knightassist/src/global/widgets/custom_circular_loader.dart';
import 'package:knightassist/src/global/widgets/custom_dialog.dart';
import 'package:knightassist/src/global/widgets/error_response_handler.dart';
import 'package:knightassist/src/global/widgets/scrollable_column.dart';
import 'package:knightassist/src/helpers/constants/app_sizes.dart';

import '../../../config/routing/routes.dart';
import '../../../global/widgets/custom_text_button.dart';
import '../../../helpers/constants/app_colors.dart';

class EventDetailsScreen extends HookConsumerWidget {
  const EventDetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authProv = ref.watch(authProvider.notifier);
    final event = ref.watch(currentEventProvider);
    final eventsProv = ref.watch(eventsProvider);

    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: ScrollableColumn(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
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
                    Text(
                      event!.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox.shrink(),
                  ],
                ),
              ),
              // Event Details
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(Sizes.p16),
                      child: Text('Image Placeholder'),
                    ),
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(Sizes.p16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(event!.name,
                              style: Theme.of(context).textTheme.titleLarge),
                          Text(event.description),
                          Text(event.maxAttendees.toString()),
                        ],
                      ),
                    ),
                  )
                ],
              ),

              // Feedback card

              // Edit Button if sponsoring org
              Visibility(
                visible: authProv.currentUserRole == UserRole.ORGANIZATION &&
                    authProv.currentUserId == event.sponsoringOrganization,
                child: CustomTextButton(
                  child: const Center(
                    child: Text(
                      'Edit Event',
                    ),
                  ),
                  onPressed: () {
                    AppRouter.pushNamed(Routes.EditEventScreenRoute);
                  },
                ),
              ),

              // RSVP and Feedback button if student
              Visibility(
                visible: authProv.currentUserRole == UserRole.VOLUNTEER,
                child: Consumer(
                  builder: (context, ref, child) {
                    return AsyncValueWidget<VolunteerModel>(
                      value: ref.watch(userVolunteerProvider),
                      loading: () => CustomCircularLoader(),
                      error: (error, st) => ErrorResponseHandler(
                        error: error,
                        stackTrace: st,
                        retryCallback: () => ref.refresh(userVolunteerProvider),
                      ),
                      data: (volunteer) {
                        return CustomTextButton(
                          width: double.infinity,
                          color: volunteer.eventsRSVP.contains(event.eventId) ||
                                  event.maxAttendees >=
                                      event.registeredVolunteers.length
                              ? AppColors.buttonGreyColor
                              : AppColors.secondaryColor,
                          child: const Center(
                            child: Text(
                              'RSVP',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                letterSpacing: 0.7,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          onPressed: () async {
                            if (event.maxAttendees >=
                                event.registeredVolunteers.length) {
                              return;
                            }
                            if (volunteer.eventsRSVP.contains(event.eventId)) {
                              final response = await eventsProv.addRSVP(
                                  eventId: event.eventId,
                                  userId: authProv.currentUserId);
                              await showDialog(
                                  context: context,
                                  builder: (ctx) => CustomDialog.alert(
                                      title: 'RSVP Cancelled',
                                      body: response,
                                      buttonText: 'OK'));
                            } else {
                              final response = await eventsProv.addRSVP(
                                  eventId: event.eventId,
                                  userId: authProv.currentUserId);
                              await showDialog(
                                  context: context,
                                  builder: (ctx) => CustomDialog.alert(
                                      title: 'RSVP Confirmed',
                                      body: response,
                                      buttonText: 'OK'));
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ));
  }
}
