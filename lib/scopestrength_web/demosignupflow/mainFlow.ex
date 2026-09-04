# ScopeStrength - personal trainer management application
# Copyright (C) 2026  Ebrahim Shahid Arshad
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# SPDX-License-Identifier: AGPL-3.0-or-later

defmodule ScopestrengthWeb.Demosignupflow.MainFlow do
  use Reactor

  alias ScopestrengthWeb.Demosignupflow.{Checklead, CreateUser, CreateLead}

  input :email

  step :check_lead, Checklead do
    argument :email, input(:email)
  end

  step :create_user, CreateUser do
    wait_for :check_lead
  end

  step :create_lead, CreateLead do
    argument :email, input(:email)
    argument :user, result(:create_user)
  end

  return :create_user
end
