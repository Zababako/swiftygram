import XCTest

extension APIIntegrationTests {
    static let __allTests = [
        ("test_API_parses_error", test_API_parses_error),
        ("test_API_parses_success", test_API_parses_success),
    ]
}

extension BotIntegrationTests {
    static let __allTests = [
        ("test_Bot_receives_info_about_itself", test_Bot_receives_info_about_itself),
        ("test_Bot_sends_file_to_its_owner_at_first_by_content_then_by_id", test_Bot_sends_file_to_its_owner_at_first_by_content_then_by_id),
        ("test_Bot_sends_message_to_its_owner", test_Bot_sends_message_to_its_owner),
        ("test_Bot_sends_message_to_itself_and_fail_because_it_is_forbidden", test_Bot_sends_message_to_itself_and_fail_because_it_is_forbidden),
        ("test_Bot_sends_message_with_keyboard_reply", test_Bot_sends_message_with_keyboard_reply),
    ]
}

extension BotTests {
    static let __allTests = [
        ("test_On_each_update_bot_requests_update_after_the_last_one_received", test_On_each_update_bot_requests_update_after_the_last_one_received),
        ("test_Updates_are_requested_infinitely", test_Updates_are_requested_infinitely),
        ("test_When_first_subscription_happens_updates_start", test_When_first_subscription_happens_updates_start),
        ("test_Updates_do_not_come_after_unsubscription", test_Updates_do_not_come_after_unsubscription),
    ]
}

extension LimiterTests {
    static let __allTests = [
        ("test_Limiter_with_limits_executes_the_first_action_as_soon_as_it_gets_one", test_Limiter_with_limits_executes_the_first_action_as_soon_as_it_gets_one),
        ("test_Limiter_without_limits_executes_actions_as_soon_as_it_gets_them", test_Limiter_without_limits_executes_actions_as_soon_as_it_gets_them),
        ("test_only_N_first_actions_are_executed_when_limit_is_reached", test_only_N_first_actions_are_executed_when_limit_is_reached),
        ("test_Two_limits_are_both_respected", test_Two_limits_are_both_respected),
    ]
}

extension MethodsTests {
    static let __allTests = [
        ("test_Conversion_from_Method_Struct_name_to_API_path_works", test_Conversion_from_Method_Struct_name_to_API_path_works),
        ("test_Send_Document_encodes_arguments_into_multipart_form_data", test_Send_Document_encodes_arguments_into_multipart_form_data),
        ("test_URL_is_composed_as_described_in_document", test_URL_is_composed_as_described_in_document),
    ]
}

extension ToolsTests {
    static let __allTests = [
        ("test_Environmental_variable_is_loaded_from_environment", test_Environmental_variable_is_loaded_from_environment),
        ("test_Environmental_variable_is_loaded_from_file", test_Environmental_variable_is_loaded_from_file),
        ("test_Environmental_variable_tries_to_load_value_from_environment_first_and_then_from_file", test_Environmental_variable_tries_to_load_value_from_environment_first_and_then_from_file),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(APIIntegrationTests.__allTests),
        testCase(BotIntegrationTests.__allTests),
        testCase(BotTests.__allTests),
        testCase(LimiterTests.__allTests),
        testCase(MethodsTests.__allTests),
        testCase(ToolsTests.__allTests),
    ]
}
#endif
