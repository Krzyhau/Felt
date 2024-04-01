#ifndef GDEXAMPLE_H
#define GDEXAMPLE_H

#include <godot_cpp/classes/resource.hpp>
#include <godot_cpp/variant/dictionary.hpp>

namespace godot
{

    class TrixelProcessor : public Resource
    {
        GDCLASS(TrixelProcessor, Resource)

    protected:
        static void _bind_methods();

    public:
        TrixelProcessor();
        ~TrixelProcessor();

        Dictionary get_trixel_faces_map(
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
            const Vector3i face_z_pos
        );
    };

}

#endif