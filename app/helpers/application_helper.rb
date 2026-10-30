module ApplicationHelper
  AVATAR_HUES = [12, 340, 28, 200, 160, 265].freeze

  def icon(name, style: "solid", **options)
    classes = ["fa-#{style}", "fa-#{name}", options.delete(:class)].compact.join(" ")
    tag.i(class: classes, "aria-hidden": true, **options)
  end

  # Cloudinary-backed photos get a resized, auto-format URL; local files are served as-is.
  def photo_url(attachment, width:, height: width)
    return if attachment.blank?

    if attachment.blob.service_name.to_s == "cloudinary"
      cl_image_path(attachment.key, width: width, height: height, crop: :fill, gravity: :auto,
                                    quality: :auto, fetch_format: :auto)
    else
      url_for(attachment)
    end
  end

  def avatar_tag(user, size: 40, **options)
    classes = ["avatar", options.delete(:class)].compact.join(" ")
    hue = AVATAR_HUES[user.id.to_i % AVATAR_HUES.size]
    style = "--avatar-size: #{size}px; --avatar-from: hsl(#{hue} 90% 68%); --avatar-to: hsl(#{hue + 30} 85% 55%)"

    tag.span(class: classes, style: style, **options) do
      if user.photo.attached?
        image_tag(photo_url(user.photo, width: size * 2), alt: "", loading: "lazy", decoding: "async")
      else
        tag.span(user.first_name.to_s.first.upcase, class: "avatar__initial")
      end
    end
  end

  def page_title(title = nil)
    [title.presence || content_for(:title), "Tinwoof"].compact_blank.uniq.join(" · ")
  end

  def tab_link(label, path, icon_name, active:, extra: nil)
    link_to path, class: ["tabbar__item", ("is-active" if active)].compact.join(" "),
                  "aria-current": (active ? "page" : nil) do
      safe_join([icon(icon_name, class: "tabbar__icon"), tag.span(label, class: "tabbar__label"), extra].compact)
    end
  end
end
