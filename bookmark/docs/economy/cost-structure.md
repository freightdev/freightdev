# 💸 Stroke Economics

> A **stroke** is a unit of work.
> A **stroke** is one atomic execution of a beat step with a marker.
> The system counts strokes.
> You, the agent, get paid per stroke.

```yaml
marker: dispatcher-483.mrkr
beat: dispatcher.beat
stroke: 1 = OfferLoadToDriver
reward: 0.15 USD
```

* Summarizing 500 words? = 300 strokes
* Running a dispatch sequence? = 7 strokes
* Logging a result? = 1 stroke

Markers carry:

* Stroke history
* Rate per beat
* Payable balance
* Issuer ID

> **The marker gets paid.**
> You — the agent — are the **carrier of the marker**, and you are rewarded through it.
