#include "trixel_processor.h"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void TrixelProcessor::_bind_methods()
{
    ClassDB::bind_method(D_METHOD(
                             "get_trixel_faces_map",
                             "buffer",
                             "layer_size_x",
                             "layer_size_y",
                             "x_index",
                             "y_index",
                             "z_offset",
                             "z_top_offset",
                             "has_top",
                             "dir_x",
                             "dir_y",
                             "face_z_pos"),
                         &TrixelProcessor::get_trixel_faces_map);
}

TrixelProcessor::TrixelProcessor()
{
    
}

TrixelProcessor::~TrixelProcessor()
{

}

Dictionary TrixelProcessor::get_trixel_faces_map(
    const PackedByteArray buffer,
    const int layer_size_x,
    const int layer_size_y,
    const int x_index,
    const int y_index,
    const int z_offset,
    const int z_top_offset,
    const bool has_top,
    const Vector3i dir_x,
    const Vector3i dir_y,
    const Vector3i face_z_pos)
{
    auto map = Dictionary();

    for (int x = 0; x < layer_size_x; x++){
        for (int y = 0; y < layer_size_y; y++){
            auto trixel_index = x * x_index + y * y_index + z_offset;
            auto top_trixel_index = x * x_index + y * y_index + z_top_offset;

            if (buffer[trixel_index] && !(has_top && buffer[top_trixel_index]))
            {
                map[x * dir_x + y * dir_y + face_z_pos] = true;
            }
        }
    }

    return map;
}