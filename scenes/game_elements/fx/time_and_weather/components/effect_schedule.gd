# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name EffectSchedule
extends Resource
## @experimental
##
## Schedule times for effects in [TimeAndWeather].

## The effect start time in the 24-hour clock. For 4 PM set it to 16.
@export_range(0.0, 24.0, 0.1, "suffix:h") var start_time: float

## The effect stop time in the 24-hour clock. For 4 PM set it to 16.
@export_range(0.0, 24.0, 0.1, "suffix:h") var stop_time: float
