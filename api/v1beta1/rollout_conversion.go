package v1beta1

import (
	"fmt"

	"github.com/openkruise/rollouts/api/v1alpha1"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/util/intstr"
	utilpointer "k8s.io/utils/pointer"
	"sigs.k8s.io/controller-runtime/pkg/conversion"
)

// ConvertTo converts this CronWork to the Hub version (v1).
func (src *Rollout) ConvertTo(dstRaw conversion.Hub) error {
	switch t := dstRaw.(type) {
	case *v1alpha1.Rollout:
		dst := dstRaw.(*v1alpha1.Rollout)
		dst.ObjectMeta = src.ObjectMeta

		dst.Spec.Disabled = true
		dst.Spec.ObjectRef = v1alpha1.ObjectRef{
			WorkloadRef: &v1alpha1.WorkloadRef{
				APIVersion: src.Spec.ObjectRef.WorkloadRef.APIVersion,
				Kind:       src.Spec.ObjectRef.WorkloadRef.Kind,
				Name:       src.Spec.ObjectRef.WorkloadRef.Name,
			},
		}
		dst.Spec.DeprecatedRolloutID = src.Spec.DeprecatedRolloutID
		dst.Spec.Strategy.Paused = src.Spec.Strategy.Paused
		dst.Spec.Strategy.Canary.FailureThreshold = src.Spec.Strategy.Canary.FailureThreshold
		dst.Spec.Strategy.Canary.

		dst.Status.Phase = v1alpha1.RolloutPhase(src.Status.Phase)
		dst.Status.Message = src.Status.Message
		dst.Status.ObservedGeneration = src.Status.ObservedGeneration
	default:
		return fmt.Errorf("unsupported type %v", t)
	}
	return nil
}

// ConvertFrom converts from the Hub version (v1) to this version.
func (dst *Rollout) ConvertFrom(srcRaw conversion.Hub) error {
	src := srcRaw.(*v1alpha1.Rollout)
	dst.ObjectMeta = src.ObjectMeta
	dst.Spec.Disabled = true
	dst.Spec.ObjectRef = ObjectRef{
		WorkloadRef: &WorkloadRef{
			APIVersion: src.Spec.ObjectRef.WorkloadRef.APIVersion,
			Kind:       src.Spec.ObjectRef.WorkloadRef.Kind,
			Name:       src.Spec.ObjectRef.WorkloadRef.Name,
		},
	}
	dst.Spec.Strategy = RolloutStrategy{
		Canary: &CanaryStrategy{
			Steps: []CanaryStep{
				{
					TrafficRoutingStrategy: TrafficRoutingStrategy{
						Weight: utilpointer.Int32(5),
					},
					Replicas: &intstr.IntOrString{IntVal: 1},
				},
			},
			TrafficRoutings: []TrafficRoutingRef{
				{
					Service: "echoserver",
					Ingress: &IngressTrafficRouting{
						Name: "echoserver",
					},
				},
			},
		},
	}
	dst.Status = RolloutStatus{
		Phase:        RolloutPhaseProgressing,
		CanaryStatus: &CanaryStatus{},
		Conditions: []RolloutCondition{
			{
				Type:   RolloutConditionProgressing,
				Reason: ProgressingReasonInitializing,
				Status: corev1.ConditionTrue,
			},
		},
	}
	return nil
}

func getCanarySteps(stepsRaw interface{}) {
	switch stepsRaw.(type) {
	case []v1alpha1.CanaryStep:
		steps := stepsRaw.([]v1alpha1.CanaryStep)
		dstStep := 
		for _, step := range steps {

		}
	}
}