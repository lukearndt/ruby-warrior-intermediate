class Player

  def play_turn(warrior)
    @warrior = warrior
    take_action!
  end

  def initialize
    @facing = :forward
    @enemy_danger =
      {
        "Wizard" => 11,
        "Archer" => 3,
        "Sludge" => 3 / 12,
        "Thick Sludge" => 3 / 24,
      }
    @health_needed_for_melee =
    {
      "Wizard" => 12,
      "Archer" => 10,
      "Sludge" => 10,
      "Thick Sludge" => 16,
      "Captive" => 0
    }
    @health_needed_for_ranged =
    {
      "Wizard" => 0,
      "Archer" => 7,
      "Sludge" => 0,
      "Thick Sludge" => 0,
      "Captive" => 0
    }
    @just_fled_from_archer = false
  end

  def take_action!
    if spot(:forward).enemy? && spot(:backward).enemy?
      attack_most_dangerous_enemy!
    elsif @just_fled_from_archer && (@warrior.health <= @health_needed_for_ranged["Archer"])
      @warrior.rest!
    elsif @warrior.feel(:backward).captive?
      @warrior.rescue!(:backward)
    elsif spot(:backward).captive?
      @warrior.walk!(:backward)
    elsif spot.captive?
      free_captive_carefully!
    elsif spot(:backward).enemy?
      engage_behind!
    elsif spot.enemy?
      engage!
    elsif spot.wall?
      turn_around!
    else
      @warrior.walk!
    end
  end

  def attack_most_dangerous_enemy!
    if most_dangerous_direction(:forward, :backward) == :forward
      skirmish!
    else
      @warrior.shoot!(:backward)
    end
  end

  def most_dangerous_direction(first, second)
    @enemy_danger[spotted_enemy_type(first)] > @enemy_danger[spotted_enemy_type(second)] ? first : second
  end

  def ranged_enemy?(direction = :forward)
    enemies.include?("Wizard") || enemies.include?("Archer")
  end

  def enemies(direction = :forward)
    enemies = []
    @warrior.look(direction).each do |space|
        enemies << space.to_s if space.enemy?
    end
    enemies
  end

  def engage_behind!
    if ranged_enemy?(:backward)
      @warrior.shoot!(:backward)
    else
      turn_around!
    end
  end

  def free_captive_carefully!
    if @warrior.feel.captive?
      if enemy_behind_enemy?("Archer")
        (healthy_enough_for_melee? || healthy_enough_for_ranged?) ? @warrior.rescue! : @warrior.rest!
      else
        @warrior.rescue!
      end
    else
      @warrior.walk!
    end
  end

  def engage!
    if @warrior.feel.enemy?
      @warrior.attack!
    elsif ranged_enemy?
      if spotted_enemy_type == "Wizard"
        skirmish!
      elsif healthy_enough_for_melee?
        charge!
      elsif healthy_enough_for_ranged?
        skirmish!
      else
        @just_fled_from_archer = true
        @warrior.walk!(:backward)
      end
    elsif healthy_enough_for_melee?
      charge!
    elsif healthy_enough_for_melee_with_one_rest?
      @warrior.rest!
    elsif healthy_enough_for_ranged?
      skirmish!
    else
      @just_fled_from_archer = true
      @warrior.walk!(:backward)
    end
  end

  def enemy_behind_enemy?(enemy_type)
    if enemies.length < 2
      false
    elsif enemies.length > 1
      enemies[1] == enemy_type
    elsif enemies.length > 2
      enemies[1] == enemy_type ||
      enemies[2] == enemy_type
    end
  end

  def skirmish!
    @warrior.feel.enemy? ? @warrior.attack! : @warrior.shoot!
    @just_fled_from_archer = false
  end

  def charge!
    @warrior.feel.enemy? ? @warrior.attack! : @warrior.walk!
    @just_fled_from_archer = false
  end

  def turn_around!
    @warrior.pivot!
    @facing = @facing == :forward ? :behind : :forward
  end

  def spot(direction = :forward)
    first_thing = @warrior.feel(direction)
    @warrior.look(direction).each do |space|
      if first_thing.empty?
        first_thing = space unless first_thing.stairs?
      end
    end
    first_thing
  end

  def spotted_enemy_type(direction = :forward)
    spot(direction).to_s
  end

  def healthy_enough_for_melee?(direction = :forward)
     @warrior.health >= @health_needed_for_melee[spotted_enemy_type] + health_buffer("Archer") + health_buffer("Wizard")
  end

  def healthy_enough_for_melee_with_one_rest?(direction = :forward)
     @warrior.health + 2 >= @health_needed_for_melee[spotted_enemy_type] + health_buffer("Archer") + health_buffer("Wizard")
  end

  def healthy_enough_for_ranged?(direction = :forward)
    if @health_needed_for_ranged[spotted_enemy_type] > 0
      @warrior.health >= spot.unit.health + health_buffer("Archer") + health_buffer("Wizard")
    else
      @warrior.health >= health_buffer("Archer") + health_buffer("Wizard")
    end
  end

  def health_buffer(enemy_type)
    if enemy_behind_enemy?(enemy_type)
      buffer = @health_needed_for_ranged[enemy_type]
    else
      0
    end
  end
end
