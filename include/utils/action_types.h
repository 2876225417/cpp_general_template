#ifndef ACTION_TYPES_H
#define ACTION_TYPES_H

#include <cstdint>


enum class ActionCategory: uint32_t {
    General    = 0x00000000,
    Annotation = 0x01000000,
    Video      = 0x02000000,
    Selection  = 0x03000000,
    File       = 0x04000000,
    Edit       = 0x05000000,
    View       = 0x06000000,
};

enum class GeneralAction: uint32_t {
    None = static_cast<uint32_t>(ActionCategory::General),
    Quit,
    About,
    Preferences,
};

enum class AnnotationAction: uint32_t {
    None = static_cast<uint32_t>(ActionCategory::Annotation),
    CreateBox,
    DeleteBox,
    SelectAll,
    DeselectAll,
    NextBox,
    PreviousBox,
    EditLabel,
    CopyBox,
    PasteBox,
};

enum class VideoAction: uint32_t {
    None = static_cast<uint32_t>(ActionCategory::Video),
    Play,
    Pause,
    Stop,
    NextFrame,
    PreviousFrame,
    SeekForward,
    SeekBackward,
    SpeedUp,
    SpeedDown,
};

enum class SelectionAction: uint32_t {
    None = static_cast<uint32_t>(ActionCategory::Selection),
    MoveUp,
    MoveDown,
    MoveLeft,
    MoveRight,
    ExpandUp,
    ExpandDown,
    ExpandLeft,
    ExpandRight,
};

enum class FileAction: uint32_t {

};

enum class EditAction: uint32_t {

};

enum class ViewAction: uint32_t {

};

using ActionId = uint32_t;

inline auto get_action_category(ActionId id) -> ActionCategory {
    return static_cast<ActionCategory>(id & 0xFF000000);
}

#endif // ACTION_TYPES_H