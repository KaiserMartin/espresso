/*
 * Copyright (C) 2010-2019 The ESPResSo project
 * Copyright (C) 2002,2003,2004,2005,2006,2007,2008,2009,2010
 *   Max-Planck-Institute for Polymer Research, Theory Group
 *
 * This file is part of ESPResSo.
 *
 * ESPResSo is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * ESPResSo is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
#ifndef REACTION_FIELD_H
#define REACTION_FIELD_H
/** \file
 *  Routines to calculate the Reaction Field energy or/and force
 *  for a particle pair @cite neumann85b.
 *
 *  Implementation in \ref reaction_field.cpp
 */

#include "config.hpp"

#ifdef ELECTROSTATICS

#include <utils/Vector.hpp>
#include <utils/math/int_pow.hpp>

/** Structure to hold Reaction Field Parameters. */
struct Reaction_field_params {
  /** ionic strength. */
  double kappa;
  /** epsilon1 (continuum dielectric constant inside). */
  double epsilon1;
  /** epsilon2 (continuum dielectric constant outside). */
  double epsilon2;
  /** Cutoff for Reaction Field interaction. */
  double r_cut;
  /** B important prefactor. */
  double B;
};

/** Structure containing the Reaction Field parameters. */
extern Reaction_field_params rf_params;

void rf_set_params(double kappa, double epsilon1, double epsilon2,
                   double r_cut);

/** Compute the Reaction Field pair force.
 *  @param q1q2      Product of the charges on p1 and p2.
 *  @param d         Vector pointing from p1 to p2.
 *  @param dist      Distance between p1 and p2.
 *  @param force     returns the force on particle 1.
 */
inline void add_rf_coulomb_pair_force(double const q1q2,
                                      Utils::Vector3d const &d,
                                      double const dist,
                                      Utils::Vector3d &force) {
  if (dist < rf_params.r_cut) {
    auto fac = 1.0 / Utils::int_pow<3>(dist) +
               rf_params.B / Utils::int_pow<3>(rf_params.r_cut);
    fac *= q1q2;
    force += fac * d;
  }
}

/** Compute the Reaction Field pair energy.
 *  @param q1q2      Product of the charges on p1 and p2.
 *  @param dist      Distance between p1 and p2.
 */
inline double rf_coulomb_pair_energy(double const q1q2, double const dist) {
  if (dist < rf_params.r_cut) {
    auto fac = 1.0 / dist - (rf_params.B * dist * dist) /
                                (2 * Utils::int_pow<3>(rf_params.r_cut));
    fac -= (1 - rf_params.B / 2) / rf_params.r_cut;
    fac *= q1q2;
    return fac;
  }
  return 0.0;
}

#endif

#endif
