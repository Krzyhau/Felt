#ifndef TRIXEL_MATERIALIZER_H
#define TRIXEL_MATERIALIZER_H

#include "trile.h"
#include <godot_cpp/classes/ref.hpp>

namespace godot {

    class TrileMaterializer {
    
    private:
        struct Plane
        {
            Vector3i pos;
            Vector2i size;
            Trile::Face face;
        };

    private:
        Ref<Trile> _trile;
    public:
        TrileMaterializer(Ref<Trile> trile);
        ~TrileMaterializer();

        void materialize();
    private:
        Array _create_materialized_mesh();
        std::set<Vector3i> _get_trixel_faces_map(Trile::Face face, int depth);
        std::list<Plane> _find_planes_in_layer(Trile::Face face, int depth);
        void _add_plane_to_mesh(const Plane plane, std::vector<Vector3>& mesh_vertices, std::vector<Vector2>& mesh_uvs);
    };
}

#endif // TRIXEL_MATERIALIZER_H