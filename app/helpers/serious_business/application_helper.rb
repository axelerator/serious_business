module SeriousBusiness
  module ApplicationHelper
    def form_for_action action, path, custom_opts = {}, &blk
      options = {
        as: action.form_model.to_param,
        url: path,
        method: :post
      }
      form_for action.form_model, options.merge(custom_opts), &blk
    end
  end
end
