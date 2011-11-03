# encoding: utf-8
require 'etc'

module WurflDevice
  class Settings
    WEBSERVICE_HOST               = '127.0.0.1'
    WEBSERVICE_PORT               = 8090
    WEBSERVICE_PID                = 'webservice.pid'
    WEBSERVICE_LOG                = 'webservice.log'
    WEBSERVICE_SOCKET             = 'webservice.sock'
    WEBSERVICE_WORKER             = 10

    BASE_DIR                      = File.join(File.expand_path('~'), '.wurfl_device')

    DB_INDEX                      = "7".freeze
    GENERIC                       = 'generic'
    GENERIC_XHTML                 = 'generic_xhtml'
    GENERIC_WEB_BROWSER           = 'generic_web_browser'

    WORST_MATCH                   = 7

    MOBILE_BROWSERS   =  [
      'cldc', 'symbian', 'midp', 'j2me', 'mobile', 'wireless', 'palm', 'phone', 'pocket pc', 'pocketpc', 'netfront',
      'bolt', 'iris', 'brew', 'openwave', 'windows ce', 'wap2.', 'android', 'opera mini', 'opera mobi', 'maemo', 'fennec',
      'blazer', 'vodafone', 'wp7', 'armv'
    ]

    ROBOTS            = [ 'bot', 'crawler', 'spider', 'novarra', 'transcoder', 'yahoo! searchmonkey', 'yahoo! slurp', 'feedfetcher-google', 'toolbar', 'mowser' ]
    DESKTOP_BROWSERS  = [ 'slcc1', '.net clr', 'wow64', 'media center pc', 'funwebproducts', 'macintosh', 'aol 9.', 'america online browser', 'googletoolbar' ]

    def self.default_wurfl_xml_file
      File.join(BASE_DIR, 'wurfl.xml') 
    end

    CAPABILITY_GROUPS = [
      "ajax",
      "bearer",
      "bugs",
      "cache",
      "chtml_ui",
      "css",
      "display",
      "drm",
      "flash_lite",
      "html_ui",
      "image_format",
      "j2me",
      "markup",
      "mms",
      "object_download",
      "pdf",
      "playback",
      "product_info",
      "rss",
      "security",
      "sms",
      "sound_format",
      "storage",
      "streaming",
      "transcoding",
      "wap_push",
      "wml_ui",
      "wta",
      "xhtml_ui",
    ]

    CAPABILITY_TO_GROUP = {
      "mobile_browser" => "product_info",
      "nokia_feature_pack" => "product_info",
      "device_os" => "product_info",
      "nokia_series" => "product_info",
      "has_qwerty_keyboard" => "product_info",
      "pointing_method" => "product_info",
      "mobile_browser_version" => "product_info",
      "is_tablet" => "product_info",
      "nokia_edition" => "product_info",
      "uaprof" => "product_info",
      "can_skip_aligned_link_row" => "product_info",
      "device_claims_web_support" => "product_info",
      "ununiqueness_handler" => "product_info",
      "model_name" => "product_info",
      "device_os_version" => "product_info",
      "uaprof2" => "product_info",
      "is_wireless_device" => "product_info",
      "uaprof3" => "product_info",
      "brand_name" => "product_info",
      "model_extra_info" => "product_info",
      "marketing_name" => "product_info",
      "can_assign_phone_number" => "product_info",
      "release_date" => "product_info",
      "unique" => "product_info",
      "unique" => "product_info",
      "icons_on_menu_items_support" => "wml_ui",
      "opwv_wml_extensions_support" => "wml_ui",
      "built_in_back_button_support" => "wml_ui",
      "proportional_font" => "wml_ui",
      "insert_br_element_after_widget_recommended" => "wml_ui",
      "wizards_recommended" => "wml_ui",
      "wml_can_display_images_and_text_on_same_line" => "wml_ui",
      "softkey_support" => "wml_ui",
      "wml_make_phone_call_string" => "wml_ui",
      "deck_prefetch_support" => "wml_ui",
      "menu_with_select_element_recommended" => "wml_ui",
      "numbered_menus" => "wml_ui",
      "card_title_support" => "wml_ui",
      "image_as_link_support" => "wml_ui",
      "wrap_mode_support" => "wml_ui",
      "table_support" => "wml_ui",
      "access_key_support" => "wml_ui",
      "wml_displays_image_in_center" => "wml_ui",
      "elective_forms_recommended" => "wml_ui",
      "times_square_mode_support" => "wml_ui",
      "break_list_of_links_with_br_element_recommended" => "wml_ui",
      "menu_with_list_of_links_recommended" => "wml_ui",
      "menu_with_list_of_links_recommended" => "wml_ui",
      "imode_region" => "chtml_ui",
      "chtml_can_display_images_and_text_on_same_line" => "chtml_ui",
      "chtml_displays_image_in_center" => "chtml_ui",
      "chtml_make_phone_call_string" => "chtml_ui",
      "chtml_table_support" => "chtml_ui",
      "chtml_display_accesskey" => "chtml_ui",
      "emoji" => "chtml_ui",
      "xhtml_preferred_charset" => "xhtml_ui",
      "xhtml_supports_css_cell_table_coloring" => "xhtml_ui",
      "xhtml_select_as_radiobutton" => "xhtml_ui",
      "xhtml_autoexpand_select" => "xhtml_ui",
      "xhtml_avoid_accesskeys" => "xhtml_ui",
      "accept_third_party_cookie" => "xhtml_ui",
      "xhtml_make_phone_call_string" => "xhtml_ui",
      "xhtml_allows_disabled_form_elements" => "xhtml_ui",
      "xhtml_supports_invisible_text" => "xhtml_ui",
      "xhtml_select_as_dropdown" => "xhtml_ui",
      "cookie_support" => "xhtml_ui",
      "xhtml_send_mms_string" => "xhtml_ui",
      "xhtml_table_support" => "xhtml_ui",
      "xhtml_display_accesskey" => "xhtml_ui",
      "xhtml_can_embed_video" => "xhtml_ui",
      "xhtml_supports_iframe" => "xhtml_ui",
      "xhtmlmp_preferred_mime_type" => "xhtml_ui",
      "xhtml_supports_monospace_font" => "xhtml_ui",
      "xhtml_supports_inline_input" => "xhtml_ui",
      "xhtml_supports_forms_in_table" => "xhtml_ui",
      "xhtml_document_title_support" => "xhtml_ui",
      "xhtml_support_wml2_namespace" => "xhtml_ui",
      "xhtml_readable_background_color1" => "xhtml_ui",
      "xhtml_format_as_attribute" => "xhtml_ui",
      "xhtml_supports_table_for_layout" => "xhtml_ui",
      "xhtml_readable_background_color2" => "xhtml_ui",
      "xhtml_select_as_popup" => "xhtml_ui",
      "xhtml_send_sms_string" => "xhtml_ui",
      "xhtml_format_as_css_property" => "xhtml_ui",
      "xhtml_file_upload" => "xhtml_ui",
      "xhtml_honors_bgcolor" => "xhtml_ui",
      "opwv_xhtml_extensions_support" => "xhtml_ui",
      "xhtml_marquee_as_css_property" => "xhtml_ui",
      "xhtml_nowrap_mode" => "xhtml_ui",
      "xhtml_nowrap_mode" => "xhtml_ui",
      "ajax_preferred_geoloc_api" => "ajax",
      "ajax_xhr_type" => "ajax",
      "ajax_support_getelementbyid" => "ajax",
      "ajax_support_event_listener" => "ajax",
      "ajax_manipulate_dom" => "ajax",
      "ajax_support_javascript" => "ajax",
      "ajax_support_inner_html" => "ajax",
      "ajax_manipulate_css" => "ajax",
      "ajax_support_events" => "ajax",
      "ajax_support_events" => "ajax",
      "html_web_3_2" => "markup",
      "html_wi_imode_htmlx_1" => "markup",
      "html_wi_imode_html_1" => "markup",
      "html_wi_oma_xhtmlmp_1_0" => "markup",
      "html_wi_imode_html_2" => "markup",
      "html_wi_w3_xhtmlbasic" => "markup",
      "html_wi_imode_compact_generic" => "markup",
      "html_wi_imode_html_3" => "markup",
      "wml_1_1" => "markup",
      "html_wi_imode_html_4" => "markup",
      "wml_1_2" => "markup",
      "html_wi_imode_html_5" => "markup",
      "wml_1_3" => "markup",
      "preferred_markup" => "markup",
      "xhtml_support_level" => "markup",
      "voicexml" => "markup",
      "html_wi_imode_htmlx_1_1" => "markup",
      "multipart_support" => "markup",
      "html_web_4_0" => "markup",
      "html_web_4_0" => "markup",
      "time_to_live_support" => "cache",
      "total_cache_disable_support" => "cache",
      "total_cache_disable_support" => "cache",
      "physical_screen_height" => "display",
      "columns" => "display",
      "dual_orientation" => "display",
      "physical_screen_width" => "display",
      "rows" => "display",
      "max_image_width" => "display",
      "resolution_height" => "display",
      "resolution_width" => "display",
      "max_image_height" => "display",
      "max_image_height" => "display",
      "greyscale" => "image_format",
      "jpg" => "image_format",
      "gif" => "image_format",
      "transparent_png_index" => "image_format",
      "epoc_bmp" => "image_format",
      "bmp" => "image_format",
      "wbmp" => "image_format",
      "gif_animated" => "image_format",
      "colors" => "image_format",
      "svgt_1_1_plus" => "image_format",
      "svgt_1_1" => "image_format",
      "transparent_png_alpha" => "image_format",
      "png" => "image_format",
      "tiff" => "image_format",
      "tiff" => "image_format",
      "emptyok" => "bugs",
      "empty_option_value_support" => "bugs",
      "basic_authentication_support" => "bugs",
      "post_method_support" => "bugs",
      "post_method_support" => "bugs",
      "nokia_voice_call" => "wta",
      "wta_pdc" => "wta",
      "wta_voice_call" => "wta",
      "wta_misc" => "wta",
      "wta_phonebook" => "wta",
      "wta_phonebook" => "wta",
      "phone_id_provided" => "security",
      "https_support" => "security",
      "https_support" => "security",
      "sdio" => "bearer",
      "wifi" => "bearer",
      "has_cellular_radio" => "bearer",
      "max_data_rate" => "bearer",
      "vpn" => "bearer",
      "vpn" => "bearer",
      "max_length_of_username" => "storage",
      "max_url_length_bookmark" => "storage",
      "max_no_of_bookmarks" => "storage",
      "max_deck_size" => "storage",
      "max_url_length_cached_page" => "storage",
      "max_length_of_password" => "storage",
      "max_no_of_connection_settings" => "storage",
      "max_url_length_in_requests" => "storage",
      "max_object_size" => "storage",
      "max_url_length_homepage" => "storage",
      "max_url_length_homepage" => "storage",
      "video" => "object_download",
      "picture_bmp" => "object_download",
      "picture" => "object_download",
      "wallpaper_df_size_limit" => "object_download",
      "picture_preferred_width" => "object_download",
      "wallpaper_oma_size_limit" => "object_download",
      "picture_greyscale" => "object_download",
      "inline_support" => "object_download",
      "ringtone_qcelp" => "object_download",
      "screensaver_oma_size_limit" => "object_download",
      "screensaver_wbmp" => "object_download",
      "picture_resize" => "object_download",
      "picture_preferred_height" => "object_download",
      "ringtone_rmf" => "object_download",
      "wallpaper_wbmp" => "object_download",
      "wallpaper_jpg" => "object_download",
      "screensaver_bmp" => "object_download",
      "screensaver_max_width" => "object_download",
      "picture_inline_size_limit" => "object_download",
      "picture_colors" => "object_download",
      "ringtone_midi_polyphonic" => "object_download",
      "ringtone_midi_monophonic" => "object_download",
      "screensaver_preferred_height" => "object_download",
      "ringtone_voices" => "object_download",
      "ringtone_3gpp" => "object_download",
      "oma_support" => "object_download",
      "ringtone_inline_size_limit" => "object_download",
      "wallpaper_preferred_width" => "object_download",
      "wallpaper_greyscale" => "object_download",
      "screensaver_preferred_width" => "object_download",
      "wallpaper_preferred_height" => "object_download",
      "picture_max_width" => "object_download",
      "picture_jpg" => "object_download",
      "ringtone_aac" => "object_download",
      "ringtone_oma_size_limit" => "object_download",
      "wallpaper_directdownload_size_limit" => "object_download",
      "screensaver_inline_size_limit" => "object_download",
      "ringtone_xmf" => "object_download",
      "picture_max_height" => "object_download",
      "screensaver_max_height" => "object_download",
      "ringtone_mp3" => "object_download",
      "wallpaper_png" => "object_download",
      "screensaver_jpg" => "object_download",
      "ringtone_directdownload_size_limit" => "object_download",
      "wallpaper_max_width" => "object_download",
      "wallpaper_max_height" => "object_download",
      "screensaver" => "object_download",
      "ringtone_wav" => "object_download",
      "wallpaper_gif" => "object_download",
      "screensaver_directdownload_size_limit" => "object_download",
      "picture_df_size_limit" => "object_download",
      "wallpaper_tiff" => "object_download",
      "screensaver_df_size_limit" => "object_download",
      "ringtone_awb" => "object_download",
      "ringtone" => "object_download",
      "wallpaper_inline_size_limit" => "object_download",
      "picture_directdownload_size_limit" => "object_download",
      "picture_png" => "object_download",
      "wallpaper_bmp" => "object_download",
      "picture_wbmp" => "object_download",
      "ringtone_df_size_limit" => "object_download",
      "picture_oma_size_limit" => "object_download",
      "picture_gif" => "object_download",
      "screensaver_png" => "object_download",
      "wallpaper_resize" => "object_download",
      "screensaver_greyscale" => "object_download",
      "ringtone_mmf" => "object_download",
      "ringtone_amr" => "object_download",
      "wallpaper" => "object_download",
      "ringtone_digiplug" => "object_download",
      "ringtone_spmidi" => "object_download",
      "ringtone_compactmidi" => "object_download",
      "ringtone_imelody" => "object_download",
      "screensaver_resize" => "object_download",
      "wallpaper_colors" => "object_download",
      "directdownload_support" => "object_download",
      "downloadfun_support" => "object_download",
      "screensaver_colors" => "object_download",
      "screensaver_gif" => "object_download",
      "screensaver_gif" => "object_download",
      "oma_v_1_0_combined_delivery" => "drm",
      "oma_v_1_0_separate_delivery" => "drm",
      "oma_v_1_0_forwardlock" => "drm",
      "oma_v_1_0_forwardlock" => "drm",
      "streaming_vcodec_mpeg4_asp" => "streaming",
      "streaming_video_size_limit" => "streaming",
      "streaming_mov" => "streaming",
      "streaming_wmv" => "streaming",
      "streaming_acodec_aac" => "streaming",
      "streaming_vcodec_h263_0" => "streaming",
      "streaming_real_media" => "streaming",
      "streaming_3g2" => "streaming",
      "streaming_3gpp" => "streaming",
      "streaming_acodec_amr" => "streaming",
      "streaming_vcodec_h264_bp" => "streaming",
      "streaming_vcodec_h263_3" => "streaming",
      "streaming_preferred_protocol" => "streaming",
      "streaming_vcodec_mpeg4_sp" => "streaming",
      "streaming_flv" => "streaming",
      "streaming_video" => "streaming",
      "streaming_mp4" => "streaming",
      "streaming_mp4" => "streaming",
      "expiration_date" => "wap_push",
      "utf8_support" => "wap_push",
      "connectionless_cache_operation" => "wap_push",
      "connectionless_service_load" => "wap_push",
      "iso8859_support" => "wap_push",
      "connectionoriented_confirmed_service_indication" => "wap_push",
      "connectionless_service_indication" => "wap_push",
      "ascii_support" => "wap_push",
      "connectionoriented_confirmed_cache_operation" => "wap_push",
      "connectionoriented_confirmed_service_load" => "wap_push",
      "wap_push_support" => "wap_push",
      "connectionoriented_unconfirmed_cache_operation" => "wap_push",
      "connectionoriented_unconfirmed_service_load" => "wap_push",
      "connectionoriented_unconfirmed_service_indication" => "wap_push",
      "connectionoriented_unconfirmed_service_indication" => "wap_push",
      "doja_1_5" => "j2me",
      "j2me_datefield_broken" => "j2me",
      "j2me_clear_key_code" => "j2me",
      "j2me_right_softkey_code" => "j2me",
      "j2me_heap_size" => "j2me",
      "j2me_canvas_width" => "j2me",
      "j2me_motorola_lwt" => "j2me",
      "doja_3_5" => "j2me",
      "j2me_wbmp" => "j2me",
      "j2me_rmf" => "j2me",
      "j2me_wma" => "j2me",
      "j2me_left_softkey_code" => "j2me",
      "j2me_jtwi" => "j2me",
      "j2me_jpg" => "j2me",
      "j2me_return_key_code" => "j2me",
      "j2me_real8" => "j2me",
      "j2me_max_record_store_size" => "j2me",
      "j2me_realmedia" => "j2me",
      "j2me_midp_1_0" => "j2me",
      "j2me_bmp3" => "j2me",
      "j2me_midi" => "j2me",
      "j2me_btapi" => "j2me",
      "j2me_locapi" => "j2me",
      "j2me_siemens_extension" => "j2me",
      "j2me_h263" => "j2me",
      "j2me_audio_capture_enabled" => "j2me",
      "j2me_midp_2_0" => "j2me",
      "j2me_datefield_no_accepts_null_date" => "j2me",
      "j2me_aac" => "j2me",
      "j2me_capture_image_formats" => "j2me",
      "j2me_select_key_code" => "j2me",
      "j2me_xmf" => "j2me",
      "j2me_photo_capture_enabled" => "j2me",
      "j2me_realaudio" => "j2me",
      "j2me_realvideo" => "j2me",
      "j2me_mp3" => "j2me",
      "j2me_png" => "j2me",
      "j2me_au" => "j2me",
      "j2me_screen_width" => "j2me",
      "j2me_mp4" => "j2me",
      "j2me_mmapi_1_0" => "j2me",
      "j2me_http" => "j2me",
      "j2me_imelody" => "j2me",
      "j2me_socket" => "j2me",
      "j2me_3dapi" => "j2me",
      "j2me_bits_per_pixel" => "j2me",
      "j2me_mmapi_1_1" => "j2me",
      "j2me_udp" => "j2me",
      "j2me_wav" => "j2me",
      "j2me_middle_softkey_code" => "j2me",
      "j2me_svgt" => "j2me",
      "j2me_gif" => "j2me",
      "j2me_siemens_color_game" => "j2me",
      "j2me_max_jar_size" => "j2me",
      "j2me_wmapi_1_0" => "j2me",
      "j2me_nokia_ui" => "j2me",
      "j2me_screen_height" => "j2me",
      "j2me_wmapi_1_1" => "j2me",
      "j2me_wmapi_2_0" => "j2me",
      "doja_1_0" => "j2me",
      "j2me_serial" => "j2me",
      "doja_2_0" => "j2me",
      "j2me_bmp" => "j2me",
      "j2me_amr" => "j2me",
      "j2me_gif89a" => "j2me",
      "j2me_cldc_1_0" => "j2me",
      "doja_2_1" => "j2me",
      "doja_3_0" => "j2me",
      "j2me_cldc_1_1" => "j2me",
      "doja_2_2" => "j2me",
      "doja_4_0" => "j2me",
      "j2me_3gpp" => "j2me",
      "j2me_video_capture_enabled" => "j2me",
      "j2me_canvas_height" => "j2me",
      "j2me_https" => "j2me",
      "j2me_mpeg4" => "j2me",
      "j2me_storage_size" => "j2me",
      "j2me_storage_size" => "j2me",
      "mms_3gpp" => "mms",
      "mms_wbxml" => "mms",
      "mms_symbian_install" => "mms",
      "mms_png" => "mms",
      "mms_max_size" => "mms",
      "mms_rmf" => "mms",
      "mms_nokia_operatorlogo" => "mms",
      "mms_max_width" => "mms",
      "mms_max_frame_rate" => "mms",
      "mms_wml" => "mms",
      "mms_evrc" => "mms",
      "mms_spmidi" => "mms",
      "mms_gif_static" => "mms",
      "mms_max_height" => "mms",
      "sender" => "mms",
      "mms_video" => "mms",
      "mms_vcard" => "mms",
      "mms_nokia_3dscreensaver" => "mms",
      "mms_qcelp" => "mms",
      "mms_midi_polyphonic" => "mms",
      "mms_wav" => "mms",
      "mms_jpeg_progressive" => "mms",
      "mms_jad" => "mms",
      "mms_nokia_ringingtone" => "mms",
      "built_in_recorder" => "mms",
      "mms_midi_monophonic" => "mms",
      "mms_3gpp2" => "mms",
      "mms_wmlc" => "mms",
      "mms_nokia_wallpaper" => "mms",
      "mms_bmp" => "mms",
      "mms_vcalendar" => "mms",
      "mms_jar" => "mms",
      "mms_ota_bitmap" => "mms",
      "mms_mp3" => "mms",
      "mms_mmf" => "mms",
      "mms_amr" => "mms",
      "mms_wbmp" => "mms",
      "built_in_camera" => "mms",
      "receiver" => "mms",
      "mms_mp4" => "mms",
      "mms_xmf" => "mms",
      "mms_jpeg_baseline" => "mms",
      "mms_midi_polyphonic_voices" => "mms",
      "mms_gif_animated" => "mms",
      "mms_gif_animated" => "mms",
      "ems" => "sms",
      "text_imelody" => "sms",
      "nokiaring" => "sms",
      "siemens_logo_height" => "sms",
      "ems_variablesizedpictures" => "sms",
      "sckl_groupgraphic" => "sms",
      "siemens_ota" => "sms",
      "sagem_v1" => "sms",
      "largeoperatorlogo" => "sms",
      "sagem_v2" => "sms",
      "ems_version" => "sms",
      "ems_odi" => "sms",
      "nokiavcal" => "sms",
      "operatorlogo" => "sms",
      "siemens_logo_width" => "sms",
      "ems_imelody" => "sms",
      "sckl_vcard" => "sms",
      "siemens_screensaver_width" => "sms",
      "sckl_operatorlogo" => "sms",
      "panasonic" => "sms",
      "ems_upi" => "sms",
      "nokiavcard" => "sms",
      "callericon" => "sms",
      "sms_enabled" => "sms",
      "gprtf" => "sms",
      "siemens_screensaver_height" => "sms",
      "sckl_ringtone" => "sms",
      "picturemessage" => "sms",
      "sckl_vcalendar" => "sms",
      "sckl_vcalendar" => "sms",
      "rmf" => "sound_format",
      "qcelp" => "sound_format",
      "awb" => "sound_format",
      "smf" => "sound_format",
      "wav" => "sound_format",
      "nokia_ringtone" => "sound_format",
      "aac" => "sound_format",
      "digiplug" => "sound_format",
      "sp_midi" => "sound_format",
      "compactmidi" => "sound_format",
      "voices" => "sound_format",
      "mp3" => "sound_format",
      "mld" => "sound_format",
      "evrc" => "sound_format",
      "amr" => "sound_format",
      "xmf" => "sound_format",
      "mmf" => "sound_format",
      "imelody" => "sound_format",
      "midi_monophonic" => "sound_format",
      "au" => "sound_format",
      "midi_polyphonic" => "sound_format",
      "midi_polyphonic" => "sound_format",
      "flash_lite_version" => "flash_lite",
      "fl_wallpaper" => "flash_lite",
      "fl_browser" => "flash_lite",
      "fl_screensaver" => "flash_lite",
      "fl_standalone" => "flash_lite",
      "full_flash_support" => "flash_lite",
      "fl_sub_lcd" => "flash_lite",
      "fl_sub_lcd" => "flash_lite",
      "css_gradient" => "css",
      "css_border_image" => "css",
      "css_rounded_corners" => "css",
      "css_spriting" => "css",
      "css_supports_width_as_percentage" => "css",
      "css_supports_width_as_percentage" => "css",
      "is_transcoder" => "transcoding",
      "transcoder_ua_header" => "transcoding",
      "transcoder_ua_header" => "transcoding",
      "rss_support" => "rss",
      "rss_support" => "rss",
      "pdf_support" => "pdf",
      "pdf_support" => "pdf",
      "playback_oma_size_limit" => "playback",
      "playback_acodec_aac" => "playback",
      "playback_vcodec_h263_3" => "playback",
      "playback_vcodec_mpeg4_asp" => "playback",
      "playback_mp4" => "playback",
      "playback_3gpp" => "playback",
      "playback_df_size_limit" => "playback",
      "playback_acodec_amr" => "playback",
      "playback_mov" => "playback",
      "playback_wmv" => "playback",
      "playback_acodec_qcelp" => "playback",
      "progressive_download" => "playback",
      "playback_directdownload_size_limit" => "playback",
      "playback_real_media" => "playback",
      "playback_3g2" => "playback",
      "playback_vcodec_mpeg4_sp" => "playback",
      "playback_vcodec_h263_0" => "playback",
      "playback_inline_size_limit" => "playback",
      "hinted_progressive_download" => "playback",
      "playback_vcodec_h264_bp" => "playback",
      "playback_vcodec_h264_bp" => "playback",
      "canvas_support" => "html_ui",
      "viewport_width" => "html_ui",
      "html_preferred_dtd" => "html_ui",
      "viewport_supported" => "html_ui",
      "viewport_minimum_scale" => "html_ui",
      "viewport_initial_scale" => "html_ui",
      "mobileoptimized" => "html_ui",
      "viewport_maximum_scale" => "html_ui",
      "viewport_userscalable" => "html_ui",
      "image_inlining" => "html_ui",
      "handheldfriendly" => "html_ui",
      "handheldfriendly" => "html_ui",
    }
  end
end
