class PreorderController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => :ipn

  def index
  end

  def checkout
  end

  def prefill
    @email = params[:email]
    token  = params[:stripeToken]

    unless @email && token
      render :checkout
      return
    end

    @user = User.find_or_create_by_email!(params[:email])

    @order = Order.prefill!(
      name:    Settings.product_name,
      price:   Settings.price,
      user_id: @user.id
    )

    # Amount in cents
    amount = Settings.price * 100

    Stripe::Charge.create(
      amount:      amount,
      card:        params[:stripeToken],
      description: Settings.product_name,
      currency:    'usd'
    )

    redirect_to action: :share, uuid: @order.uuid
  end

  def postfill
    unless params[:callerReference].blank?
      @order = Order.postfill!(params)
    end

    # "A" means the user cancelled the preorder before clicking "Confirm" on
    # Amazon Payments.
    if params['status'] != 'A' && @order.present?
      redirect_to :action => :share, :uuid => @order.uuid
    else
      redirect_to root_url
    end
  end

  def share
    @order = Order.find_by_uuid(params[:uuid])
  end

  def ipn
  end
end
