#ifndef TRIXEL_DEMATERIALIZER_H
#define TRIXEL_DEMATERIALIZER_H

#include "trile.h"
#include <godot_cpp/classes/ref.hpp>

namespace godot {

    class TrileDematerializer {
    
    private:
        enum SandwichState : unsigned char
        {
            NONE,
            ENTRY,
            EXIT,
            BOTH
        };

    private:
        Ref<Trile> _trile;
        std::vector<SandwichState> _sandwich_data;

    public:
        TrileDematerializer(Ref<Trile> trile);
        ~TrileDematerializer();

        void dematerialize();
    private:
        void _rasterize_trile_mesh();
        void _populate_sandwich_data();
    };
}

#endif // TRIXEL_DEMATERIALIZER_H