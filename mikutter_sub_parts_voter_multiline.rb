miquire :mui, 'sub_parts_helper'

require 'gtk2'
require 'cairo'

class ::Gdk::SubPartsVoter < Gdk::SubParts
  attr_reader :votes, :icon_width, :icon_height, :margin

  def initialize(*args)
    super
    @icon_width, @icon_height, @margin, @votes, @user_icon = 24, 24, 2, get_default_votes.to_a, Hash.new
    @icon_ofst = 0
    helper.ssc(:click){ |this, e, x, y|
      case e.button
      when 1
        user = get_user_by_point_with_offset(x, y)
        if user
          Plugin.call(:show_profile, Service.primary, user) end end
      false }
    usertip = Gtk::Tooltips.new
    helper.ssc(:motion_notify_event){ |this, x, y|
      user = get_user_by_point_with_offset(x, y)
      if user
        usertip.set_tip(helper.tree, user.idname, '')
        usertip.enable
      else
        usertip.set_tip(helper.tree, '', '')
        usertip.disable end
      false }
    helper.ssc(:leave_notify_event){
      usertip.set_tip(helper.tree, '', '')
      usertip.disable
      false }
  end

  def height
    if get_vote_count == 0
      0
    else
      [(@votes.size.to_f / max_voter_per_line).ceil, 1].max * @icon_height end end

  def delete(user)
    if UserConfig[:"#{name}_by_anyone_show_timeline"]
      if @votes.include?(user)
        before_height = height
        @votes.delete(user)
        if before_height == height
          helper.on_modify
        else
          helper.reset_height end
        self end end end

  private

  def get_user_by_point_with_offset(x, y)
    if height != 0
      ofsty = helper.mainpart_height
      helper.subparts.each{ |part|
        break if part == self
        ofsty += part.height }
      if ofsty <= y and (ofsty + height) > y
        get_user_by_point(x - @margin - @icon_ofst, y - ofsty) end end end

  def get_user_by_point(x, y)
    if x >= 0 and x < max_voter_per_line * @icon_width
      index = ((y / @icon_height) * max_voter_per_line) + (x / @icon_width)
      @votes[index] end end

  def max_voter_per_line
    ((width - @margin - @icon_ofst) / @icon_width) end

  def put_voter(context)
    votes.each_with_index{ |user, i|
      context.save {
        context.translate(@icon_ofst + (i % max_voter_per_line) * @icon_width, (i / max_voter_per_line) * @icon_height)
        render_user(context, user) } } end

  def render_icon(context, user)
    context.set_source_pixbuf(user_icon(user))
    context.paint
  end
end

Plugin.create(:mikutter_sub_parts_voter_multiline) { }
