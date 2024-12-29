//
//  TermsOfServiceView.swift
//  Zap
//
//  Created by Zigao Wang on 9/28/24.
//

import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            Text(termsOfService)
                .padding()
        }
        .navigationTitle("Terms of Service")
    }
    
    private var termsOfService: String {
        let preferredLanguages = Bundle.main.preferredLocalizations
        let isChineseLanguage = preferredLanguages.first?.hasPrefix("zh") ?? false
        
        if isChineseLanguage {
            return """
            Zap 笔记服务条款

            1. 条款接受
            使用 Zap 应用即表示您同意这些服务条款。如果您不同意条款的任何部分，请勿使用我们的应用。

            2. 开源许可
            Zap 是开源软件，采用 GNU 通用公共许可证 v3.0 (GPL-3.0) 授权。您可以在 GitHub 上找到源代码：
            - 应用：https://github.com/ZigaoWang/Zap
            - 后端：https://github.com/ZigaoWang/Zap-backend

            3. 第三方服务
            Zap 使用 https://uniapi.ai/ 作为 OpenAI 服务的代理。使用 Zap 即表示您同意遵守 UniAPI 的服务条款。

            4. 免责声明
            本应用按"原样"提供。我们不提供任何明示或暗示的保证，特此声明并否认所有其他保证，包括但不限于对适销性、特定用途适用性或不侵犯知识产权或其他权利的暗示保证或条件。

            5. 责任限制
            在任何情况下，我们或我们的供应商均不对因使用或无法使用本应用而产生的任何损害负责。

            6. 修改
            我们可能随时修改这些服务条款，恕不另行通知。使用本应用即表示您同意受这些服务条款当前版本的约束。

            7. 联系
            如果您对这些服务条款有任何疑问，请通过 a@zigao.wang 与我们联系。

            最后更新：2024年10月17日
            """
        } else {
            return """
            Terms of Service for Zap Notes

            1. Acceptance of Terms
            By using the Zap app, you agree to these Terms of Service. If you disagree with any part of the terms, you may not use our app.

            2. Open Source License
            Zap is open-source software, licensed under the GNU General Public License v3.0 (GPL-3.0). You can find the source code on GitHub:
            - App: https://github.com/ZigaoWang/Zap
            - Backend: https://github.com/ZigaoWang/Zap-backend

            3. Third-Party Services
            Zap uses https://uniapi.ai/ as a proxy for OpenAI services. By using Zap, you also agree to comply with UniAPI's terms of service.

            4. Disclaimer
            The app is provided on an 'as is' basis. We make no warranties, expressed or implied, and hereby disclaim and negate all other warranties including, without limitation, implied warranties or conditions of merchantability, fitness for a particular purpose, or non-infringement of intellectual property or other violation of rights.

            5. Limitations
            In no event shall we or our suppliers be liable for any damages arising out of the use or inability to use the app.

            6. Modifications
            We may revise these terms of service at any time without notice. By using this app, you are agreeing to be bound by the current version of these terms of service.

            7. Contact
            If you have any questions about these Terms of Service, please contact us at a@zigao.wang.

            Last updated: October 17, 2024
            """
        }
    }
}
