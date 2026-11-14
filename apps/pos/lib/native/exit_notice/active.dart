/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

import 'package:pn_types/src/native/exit_notice_port.dart';
import 'package:pos/native/exit_notice/exit_notice_channel.dart';

ExitNoticePort get exitNotice => _exitNotice;
ExitNoticePort _exitNotice = ChannelExitNotice();

/// Replaces the implementation. Called by a test with a fake; not by the app
/// (`.claude/rules/native-ports.md` §2.4).
void setExitNotice(ExitNoticePort impl) => _exitNotice = impl;
