describe PaymentNotificationsController, type: :controller do
  before do
    PaymentNotification.destroy_all
    @u = User.create! is_pro: false
    stub_request(:post, /https:\/\/www.sandbox.paypal.com\/(.*)/).
      to_return(:status => 200, :body => "VERIFIED", :headers => {})
  end
  it "receives payments" do
    payload = JSON.parse(fixture('paypal/subscr_payment.json')).merge(custom: @u.id)
    post :create, payload
    @u.reload
    expect(@u.is_pro).to eq(true)
  end
  it "receives cancellations" do

    # first pay
    payload = JSON.parse(fixture('paypal/subscr_payment.json')).merge(custom: @u.id)
    post :create, payload

    # then cancel
    payload = JSON.parse(fixture('paypal/subscr_cancel.json')).merge(custom: @u.id)
    post :create, payload
    @u.reload
    expect(@u.is_pro).to eq(false)
  end
  it "creates an upgrading" do
    @u.update(is_pro: false)
    expect(@u.upgrading).to be(nil)
    payload = JSON.parse(fixture('paypal/subscr_payment.json')).merge(custom: @u.id)
    post :create, payload
    @u.reload
    expect(@u.is_pro).to eq(true)
    expect(@u.upgrading).not_to be(nil)
  end
end
